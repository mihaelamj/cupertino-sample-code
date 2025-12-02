/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the app's view controller.
*/
#import "AAPLViewController.h"
#import "AAPLRenderer.h"

@implementation AAPLViewController
{
    MTKView* _mtkView;
    AAPLRenderer* _renderer;
#if TARGET_OS_IOS
    __weak IBOutlet UILabel *_infoLabel;
    __weak IBOutlet UISwitch *_toggleAnimationSwitchButton;
#elif TARGET_OS_OSX
    __weak IBOutlet NSTextField *_infoLabel;
    __weak IBOutlet NSSwitch *_toggleAnimationSwitchButton;
#endif
}

/// Initializes the Metal view, checks for sparse texture support, and initializes the renderer.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize the Metal View.
    _mtkView = (MTKView*)self.view;
    _mtkView.device = MTLCreateSystemDefaultDevice();
    
    NSAssert(_mtkView.device, @"Metal isn't supported on this device.");

    // Metal sparse textures require at least MTLGPUFamilyApple6.
    if (![_mtkView.device supportsFamily:MTLGPUFamilyApple6])
    {
        NSAssert (0, @"This device doesn't support Metal sparse textures.");
    }
    
    // Initialize AAPLRenderer and resize the view.
    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_mtkView];
    
    NSAssert(_renderer, @"The renderer failed to initialize.");
    
    [_renderer mtkView:_mtkView drawableSizeWillChange:_mtkView.drawableSize];
    _mtkView.delegate = self;
}

/// The callback to toggle camera movement.
- (IBAction)optionsChanged:(id)sender
{
#if TARGET_OS_IOS
    _renderer.animationEnabled = _toggleAnimationSwitchButton.isOn;
#elif TARGET_OS_OSX
    _renderer.animationEnabled = _toggleAnimationSwitchButton.state == NSControlStateValueOn;
#endif
}

/// The callback when the view size changes size.
- (void)mtkView:(nonnull MTKView*)view drawableSizeWillChange:(CGSize)size
{
    [_renderer mtkView:view drawableSizeWillChange:view.bounds.size];
}

/// The callback for drawing the frame and updating the information label text.
- (void)drawInMTKView:(nonnull MTKView*) view
{
    [_renderer drawInMTKView:view];
#if TARGET_OS_IOS
    _infoLabel.text = _renderer.infoString;
#elif TARGET_OS_OSX
    [_infoLabel setStringValue: _renderer.infoString];
#endif
}

@end
