#import "SimpleVideoFilterViewController.h"

// Change this factor to increase the threshold of skin repair effect.
const float factor = 1.5;

@implementation SimpleVideoFilterViewController

@synthesize starting;
@synthesize button;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    filter = [[GPUSkinRepairFilter alloc] initWithTexelSize:1.5];
	[filter addTarget:(GPUImageView*)self.view];

//    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
//    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraPosition:AVCaptureDevicePositionBack];
//    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset1920x1080 cameraPosition:AVCaptureDevicePositionBack];

    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoCamera.horizontallyMirrorFrontFacingCamera = NO;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;

    [videoCamera addTarget:filter];
    [videoCamera startCameraCapture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    // Map UIDeviceOrientation to UIInterfaceOrientation.
    UIInterfaceOrientation orient = UIInterfaceOrientationPortrait;
    switch ([[UIDevice currentDevice] orientation])
    {
        case UIDeviceOrientationLandscapeLeft:
            orient = UIInterfaceOrientationLandscapeLeft;
            break;

        case UIDeviceOrientationLandscapeRight:
            orient = UIInterfaceOrientationLandscapeRight;
            break;

        case UIDeviceOrientationPortrait:
            orient = UIInterfaceOrientationPortrait;
            break;

        case UIDeviceOrientationPortraitUpsideDown:
            orient = UIInterfaceOrientationPortraitUpsideDown;
            break;

        case UIDeviceOrientationFaceUp:
        case UIDeviceOrientationFaceDown:
        case UIDeviceOrientationUnknown:
            // When in doubt, stay the same.
            orient = fromInterfaceOrientation;
            break;
    }
    videoCamera.outputImageOrientation = orient;

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES; // Support all orientations.
}

- (IBAction)updateSliderValue:(id)sender
{
	((GPUSkinRepairFilter*)filter).texelSize = [(UISlider *)sender value] * 1.5 * factor;
}

- (void)start
{
	NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]); // If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
	
	movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
    movieWriter.encodingLiveVideo = YES;
	
	[filter addTarget:movieWriter];
	videoCamera.audioEncodingTarget = movieWriter;
	[movieWriter startRecording];
}

- (void)stop
{
	[filter removeTarget:movieWriter];
	videoCamera.audioEncodingTarget = nil;
	[movieWriter finishRecording];
	[movieWriter release];
	NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
	UISaveVideoAtPathToSavedPhotosAlbum(pathToMovie, nil, nil, nil);
}

- (IBAction)StartStop:(id)sender
{
	if (starting)
	{
		[self stop];
	}
	else
	{
		[self start];
	}
	starting = !starting;
	if (starting)
	{
		[button setTitle:@"Stop" forState:UIControlStateNormal];
	}
	else
	{
		[button setTitle:@"Start" forState:UIControlStateNormal];
	}
}

@end
