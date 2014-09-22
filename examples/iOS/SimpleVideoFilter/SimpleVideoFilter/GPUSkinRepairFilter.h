
#import "GPUImage.h"

@interface GPUSkinRepairFilter : GPUImageTwoPassTextureSamplingFilter
{
	GLint luminanceTextureUniform, chrominanceTextureUniform;
}

- initWithTexelSize:(float)texelSize;

@property (nonatomic, readwrite) float texelSize;

@end
