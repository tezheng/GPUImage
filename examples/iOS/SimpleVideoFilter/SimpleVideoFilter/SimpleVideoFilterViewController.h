#import <UIKit/UIKit.h>
#import "GPUImage.h"

@interface SimpleVideoFilterViewController : UIViewController
{
    GPUImageVideoCamera *videoCamera;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *movieWriter;
}

- (IBAction)updateSliderValue:(id)sender;

- (IBAction)StartStop:(id)sender;

@property(nonatomic) BOOL starting;

@property(nonatomic, retain) IBOutlet UIButton *button;
@end
