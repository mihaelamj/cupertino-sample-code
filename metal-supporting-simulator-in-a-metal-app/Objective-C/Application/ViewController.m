/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller.
*/

#import "ViewController.h"
#import "Renderer.h"

@implementation ViewController
{
    MTKView *_view;

    Renderer *_renderer;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView *)self.view;

    _view.device = MTLCreateSystemDefaultDevice();

#ifndef TARGET_MACOS
    _view.backgroundColor = UIColor.blackColor;
#endif

    NSAssert(_view.device, @"Metal is not supported on this device");

    _renderer = [[Renderer alloc] initWithMetalKitView:_view];

    NSAssert(_renderer, @"Could not initialize renderer");

#ifdef TARGET_IOS
    [_renderer setBlendMode:BlendModeTransparency];
    [_renderer setTransparency:_transparencySlider.value];
#endif

    [_renderer mtkView:_view drawableSizeWillChange:_view.bounds.size];

    _view.delegate = _renderer;
}

#ifdef TARGET_IOS
- (IBAction)transparencyChanged:(UISlider *)sender {
    [_renderer setTransparency:sender.value];
}

- (IBAction)blendModeChanged:(UISegmentedControl *)sender {    
    [_renderer setBlendMode:(BlendMode)sender.selectedSegmentIndex];
    _transparencySlider.hidden = ((BlendMode)sender.selectedSegmentIndex != BlendModeTransparency);
}
#endif

@end
