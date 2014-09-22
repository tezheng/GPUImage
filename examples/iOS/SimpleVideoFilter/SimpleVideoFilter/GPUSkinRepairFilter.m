
#import "GPUSkinRepairFilter.h"

@implementation GPUSkinRepairFilter
{
	GPUImagePicture* _lookupImageSource;
};

#pragma mark Shader

NSString *const kSkinRepairVS = SHADER_STRING
(
attribute vec4 position;
attribute vec2 inputTextureCoordinate;

uniform float texelWidthOffset;
uniform float texelHeightOffset;

varying highp vec2 textureCoordinate;     
varying vec2 blurCoordinates[11];

void main()
{
	gl_Position = position;
	textureCoordinate = inputTextureCoordinate;

	vec2 singleStepOffset = vec2(texelWidthOffset, texelHeightOffset);
	blurCoordinates[0] = inputTextureCoordinate.xy;
    blurCoordinates[1] = inputTextureCoordinate.xy + singleStepOffset * 1.481490;
    blurCoordinates[2] = inputTextureCoordinate.xy - singleStepOffset * 1.481490;
    blurCoordinates[3] = inputTextureCoordinate.xy + singleStepOffset * 3.456897;
    blurCoordinates[4] = inputTextureCoordinate.xy - singleStepOffset * 3.456897;
    blurCoordinates[5] = inputTextureCoordinate.xy + singleStepOffset * 5.432513;
    blurCoordinates[6] = inputTextureCoordinate.xy - singleStepOffset * 5.432513;
    blurCoordinates[7] = inputTextureCoordinate.xy + singleStepOffset * 7.408452;
    blurCoordinates[8] = inputTextureCoordinate.xy - singleStepOffset * 7.408452;
    blurCoordinates[9] = inputTextureCoordinate.xy + singleStepOffset * 9.000000;
    blurCoordinates[10] = inputTextureCoordinate.xy - singleStepOffset * 9.000000;
}
);


NSString *const kSkinRepairFSFirstPass = SHADER_STRING
(
varying highp vec2 textureCoordinate;
uniform highp float texelWidthOffset;
uniform highp float texelHeightOffset;

varying highp vec2 blurCoordinates[11];
uniform sampler2D luminanceTexture;
uniform sampler2D chrominanceTexture;

void main()
{
	lowp vec3 yuv;
	yuv.x  = texture2D(luminanceTexture, textureCoordinate).r;
	yuv.yz = texture2D(chrominanceTexture, textureCoordinate).ra;

	mediump float sum = 0.0;
	sum += texture2D(luminanceTexture, blurCoordinates[0]).r * 0.091811;
	sum += texture2D(luminanceTexture, blurCoordinates[1]).r * 0.172749;
	sum += texture2D(luminanceTexture, blurCoordinates[2]).r * 0.172749;
	sum += texture2D(luminanceTexture, blurCoordinates[3]).r * 0.135364;
	sum += texture2D(luminanceTexture, blurCoordinates[4]).r * 0.135364;
	sum += texture2D(luminanceTexture, blurCoordinates[5]).r * 0.087268;
	sum += texture2D(luminanceTexture, blurCoordinates[6]).r * 0.087268;
	sum += texture2D(luminanceTexture, blurCoordinates[7]).r * 0.046287;
	sum += texture2D(luminanceTexture, blurCoordinates[8]).r * 0.046287;
	sum += texture2D(luminanceTexture, blurCoordinates[9]).r * 0.012425;
	sum += texture2D(luminanceTexture, blurCoordinates[10]).r * 0.012425;
	gl_FragColor = vec4(yuv, sum);
}
);


NSString *const kSkinRepairFSSecondPass = SHADER_STRING
(
precision mediump float;

varying highp vec2 textureCoordinate;
uniform highp float texelWidthOffset;
uniform highp float texelHeightOffset;

varying highp vec2 blurCoordinates[11];
uniform sampler2D inputImageTexture;
uniform sampler2D inputImageTexture2;

void main()
{
	vec4 yuv = texture2D(inputImageTexture, textureCoordinate);

	float sum = 0.0;
	sum += texture2D(inputImageTexture, blurCoordinates[0]).a * 0.091811;
	sum += texture2D(inputImageTexture, blurCoordinates[1]).a * 0.172749;
	sum += texture2D(inputImageTexture, blurCoordinates[2]).a * 0.172749;
	sum += texture2D(inputImageTexture, blurCoordinates[3]).a * 0.135364;
	sum += texture2D(inputImageTexture, blurCoordinates[4]).a * 0.135364;
	sum += texture2D(inputImageTexture, blurCoordinates[5]).a * 0.087268;
	sum += texture2D(inputImageTexture, blurCoordinates[6]).a * 0.087268;
	sum += texture2D(inputImageTexture, blurCoordinates[7]).a * 0.046287;
	sum += texture2D(inputImageTexture, blurCoordinates[8]).a * 0.046287;
	sum += texture2D(inputImageTexture, blurCoordinates[9]).a * 0.012425;
	sum += texture2D(inputImageTexture, blurCoordinates[10]).a * 0.012425;

	float mask = texture2D(inputImageTexture2, vec2(sum, yuv.r)).r;
	vec3 rgb = mat3(      1,       1,      1,
					      0, -.18732, 1.8556,
					1.57481, -.46813,      0) * vec3(yuv.r, yuv.gb - vec2(0.5, 0.5));

	float r = texture2D(inputImageTexture2, vec2(mask, rgb.r)).g;
	float g = texture2D(inputImageTexture2, vec2(mask, rgb.g)).g;
	float b = texture2D(inputImageTexture2, vec2(mask, rgb.b)).g;
	gl_FragColor = vec4(r, g, b, 1.0);
}
);


#pragma mark Code - Initialization
- initWithTexelSize:(float)texelSize
{
	self = [super initWithFirstStageVertexShaderFromString:kSkinRepairVS
						firstStageFragmentShaderFromString:kSkinRepairFSFirstPass
						 secondStageVertexShaderFromString:kSkinRepairVS
					   secondStageFragmentShaderFromString:kSkinRepairFSSecondPass];
	if (self == nil)
		return nil;

	UIImage *image = [UIImage imageNamed:@"mask.png"];
    _lookupImageSource = [[GPUImagePicture alloc] initWithImage:image];

	runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        luminanceTextureUniform = [filterProgram uniformIndex:@"luminanceTexture"];
        chrominanceTextureUniform = [filterProgram uniformIndex:@"chrominanceTexture"];
		secondFilterInputTextureUniform2 = [secondFilterProgram uniformIndex:@"inputImageTexture2"];
    });

	self.verticalTexelSpacing = texelSize;
	self.horizontalTexelSpacing = texelSize;

	return self;
}


#pragma mark Code - Inherience
- (BOOL)wantsMonochromeInput
{
	return YES;
}

- (void)setUniformsForProgramAtIndex:(NSUInteger)programIndex;
{
    [super setUniformsForProgramAtIndex:programIndex];

    if (programIndex == 0)
    {
        glUniform1i(luminanceTextureUniform, 4);
        glUniform1i(chrominanceTextureUniform, 5);
    }
	else if (programIndex == 1)
	{
		GLint textureID = [_lookupImageSource framebufferForOutput].texture;
		glActiveTexture(GL_TEXTURE1);
		glBindTexture(GL_TEXTURE_2D, textureID);
		glUniform1i(secondFilterInputTextureUniform2, textureID);
	}
}

#pragma mark Property
- (void)setTexelSize:(float)texelSize
{
	self.verticalTexelSpacing = texelSize;
	self.horizontalTexelSpacing = texelSize;
}

@end
