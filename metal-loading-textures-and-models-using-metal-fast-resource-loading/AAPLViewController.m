/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the iOS view controller.
*/

#import "AAPLConfig.h"
#import "AAPLViewController.h"
#import "Renderer/AAPLRenderer.h"

@implementation AAPLViewController
{
    MTKView* _mtkView;
    AAPLRenderer* _renderer;
    BOOL _useMTLIO;

    __weak IBOutlet NSTextField* _infoLabel;
    __weak IBOutlet NSSwitch*    _toggleAnimationSwitchButton;
    __weak IBOutlet NSSwitch*    _toggleMTLIO;
    __weak IBOutlet NSButton*    _reloadButton;
}

/// Initializes Metal View, checks for Sparse Texture support, and initializes Renderer.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Initialize the Metal View.
    _mtkView = (MTKView*)self.view;
    _mtkView.device = MTLCreateSystemDefaultDevice();
    
    NSAssert(_mtkView.device, @"Metal is not supported on this device");

    // Fast resource loading and ASTC textures require at least MTLGPUFamilyApple6.
    _useMTLIO = AAPL_USE_MTLIO;
    if (![_mtkView.device supportsFamily:MTLGPUFamilyApple6])
    {
        NSAssert(0, @"This device does not support Metal fast resource loading");
        _useMTLIO = NO;
    }
    
    // Initialize AAPLRenderer and resize the view.
    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_mtkView];
    
    NSAssert(_renderer, @"Renderer failed to initialize");
    
    [_renderer mtkView:_mtkView drawableSizeWillChange:_mtkView.drawableSize];
    _mtkView.delegate = self;
    
    // Propagate the initial state to the renderer.
    [self optionsChanged:self];
}

/// The callback to toggle object animation.
- (IBAction)optionsChanged:(id)sender
{
    _renderer.cycleDetailedObjects = ([_toggleAnimationSwitchButton state] == NSControlStateValueOn);
    if (_useMTLIO)
    {
        _renderer.useMTLIO = ([_toggleMTLIO state] == NSControlStateValueOn);
    }
    else
    {
        _renderer.useMTLIO = false;
        [_toggleMTLIO setState:NSControlStateValueOff];
    }
}

/// The callback to clear the high-resolution buffers to trigger a reload.
- (IBAction)reloadDetailedObject:(id)sender
{
    _renderer.reloadDetailedObject = true;
}

/// The callback when the view changes size.
- (void) mtkView:(nonnull MTKView*) view drawableSizeWillChange:(CGSize)size
{
    [_renderer mtkView:view drawableSizeWillChange:size];
}

/// The callback when updating the info label text.
- (void) drawInMTKView:(nonnull MTKView*) view
{
    [_renderer drawInMTKView:view];
    if (_renderer.infoString)
    {
        if (_renderer.infoString)
        {
            [_infoLabel setStringValue: _renderer.infoString];
        }
    }
}

@end
