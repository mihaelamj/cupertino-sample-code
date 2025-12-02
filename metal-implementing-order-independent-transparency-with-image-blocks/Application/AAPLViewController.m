/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main view controller.
*/

#import "AAPLViewController.h"
#import "AAPLRenderer.h"

@implementation AAPLViewController
{
    MTKView* _mtkView;
    AAPLRenderer* _renderer;

#if TARGET_OS_IPHONE

    __weak IBOutlet UISegmentedControl *_orderIndependentTransparencyControl;

#elif TARGET_OS_OSX

    __weak IBOutlet NSSegmentedControl *_orderIndependentTransparencyControl;

#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _mtkView = (MTKView*)self.view;
    _mtkView.device = MTLCreateSystemDefaultDevice();

    NSAssert(_mtkView.device, @"Metal is not supported on this device");

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_mtkView];

    NSAssert(_renderer, @"Renderer failed to initialize");

    [_renderer mtkView:_mtkView drawableSizeWillChange:_mtkView.drawableSize];

    _mtkView.delegate = _renderer;

    if (_renderer.supportsOrderIndependentTransparency)
    {
        _orderIndependentTransparencyControl.enabled = YES;
    }
    else
    {
        _orderIndependentTransparencyControl.enabled = NO;
    }

    NSUInteger segmentSelectionIndex = (_renderer.enableOrderIndependentTransparency) ? 0 : 1;

#if TARGET_OS_IPHONE
    _orderIndependentTransparencyControl.selectedSegmentIndex = segmentSelectionIndex;
#else
    [_orderIndependentTransparencyControl setSelected:YES forSegment:segmentSelectionIndex];
#endif
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

#if TARGET_OS_IPHONE

- (IBAction)updateTransparencyMethod:(UISegmentedControl *)transparencyControl
{
    if (!transparencyControl.selectedSegmentIndex)
    {
        _renderer.enableOrderIndependentTransparency = YES;
    }
    else
    {
        _renderer.enableOrderIndependentTransparency = NO;
    }
}

- (IBAction)toggleRotation:(UISwitch *)rotationControl
{
    if (rotationControl.on)
    {
        _renderer.enableRotation = YES;
    }
    else
    {
        _renderer.enableRotation = NO;
    }
}

#elif TARGET_OS_OSX

- (IBAction)updateTransparencyMethod:(NSSegmentedControl *)transparencyControl
{
    if (!transparencyControl.selectedSegment)
    {
        _renderer.enableOrderIndependentTransparency = YES;
    }
    else
    {
        _renderer.enableOrderIndependentTransparency = NO;
    }
}

- (IBAction)toggleRotation:(NSSwitch *)rotationControl
{
    if (rotationControl.state == NSControlStateValueOn)
    {
        _renderer.enableRotation = YES;
    }
    else
    {
        _renderer.enableRotation = NO;
    }
}

- (void)viewDidAppear
{
    // Set the view to handle Key events by making it the window's first responder.
    [_mtkView.window makeFirstResponder:self];
}

#endif

@end
