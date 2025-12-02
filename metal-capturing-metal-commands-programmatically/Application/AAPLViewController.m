/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the main view controller.
*/

@import MetalKit;
#import "AAPLViewController.h"
#import "AAPLRenderer.h"

@implementation AAPLViewController
{
    MTKView *_view;

    AAPLRenderer *_renderer;

    IBOutlet NSButton *_captureInXcodeButton;
    IBOutlet NSButton *_captureToFileButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView *)self.view;

    _view.device = MTLCreateSystemDefaultDevice();

    if (!_view.device)
    {
        NSLog(@"Metal is not supported on this device.");
        self.view = [[NSView alloc] initWithFrame:self.view.frame];
        return;
    }

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];

    [_renderer mtkView:_view drawableSizeWillChange:_view.bounds.size];

    _view.delegate = _renderer;

    MTLCaptureManager *captureManager = MTLCaptureManager.sharedCaptureManager;

    if (![captureManager supportsDestination:MTLCaptureDestinationDeveloperTools])
    {
        _captureInXcodeButton.enabled = NO;
    }

    if (![captureManager supportsDestination:MTLCaptureDestinationGPUTraceDocument])
    {
        _captureToFileButton.enabled = NO;
    }
}

#pragma mark - IBAction Methods

- (IBAction)captureInXcode:(id)sender
{
    [_renderer.captureManager setupCaptureInXcode:_view];
}

- (IBAction)captureToFile:(id)sender
{
    [_renderer.captureManager setupCaptureToFile:_view];
}

@end
