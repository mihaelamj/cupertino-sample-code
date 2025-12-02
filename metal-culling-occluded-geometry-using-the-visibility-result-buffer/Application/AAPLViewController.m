/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The cross-platform view controller.
*/

#import "AAPLViewController.h"
#import "AAPLRenderer.h"

@implementation AAPLViewController
{
    MTKView*        _view;
    AAPLRenderer*   _renderer;
    
#if defined(TARGET_MACOS)
    __weak IBOutlet NSSegmentedControl *_mode;
    __weak IBOutlet NSTextField *_numDisplay;
    __weak IBOutlet NSTextField *_modeDisplay;
    __weak IBOutlet NSTextField *_posX;
    __weak IBOutlet NSSlider *_position;
#elif defined(TARGET_IOS) || defined(TARGET_TVOS)
    __weak IBOutlet UISegmentedControl *_mode;
    __weak IBOutlet UITextField *_numDisplay;
    __weak IBOutlet UITextField *_modeDisplay;
#if defined(TARGET_IOS)
    __weak IBOutlet UITextField *_posX;
    __weak IBOutlet UISlider *_position;
#endif
#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _view = (MTKView *)self.view;

    _view.device = MTLCreateSystemDefaultDevice();
    NSAssert(_view.device, @"Metal is not supported on this device");

    // Check if the GPU device supports the 'counting occlusion query' feature.
    if (![_view.device supportsFamily:MTLGPUFamilyApple3])
    {
        NSLog(@"This GPU device doesn't support the 'counting occlusion query' feature.");

        // Create an empty view.
    #if defined(TARGET_MACOS)
        self.view = [[NSView alloc] initWithFrame:_view.frame];
    #else
        self.view = [UIView new];
        self.view.backgroundColor = [[UIColor alloc] initWithRed:1 green:0 blue:0 alpha:1];
    #endif
        return;
    }

    _renderer = [[AAPLRenderer alloc] initWithMetalKitView:_view];
    NSAssert(_renderer, @"Renderer failed initialization");

    [_renderer drawableSizeWillChange:_view.bounds.size];

    // The view controller needs to update state for the renderer, so use this class's `MTKView` methods first.
    _view.delegate = self;
    
    // Run the callbacks on the first run to properly set up the app.
    [self optionChanged:self];
    [self modeChanged:self];
}

- (IBAction)optionChanged:(id)sender
{
#if defined(TARGET_MACOS)
    _renderer.position = [_position floatValue];
#elif defined(TARGET_IOS)
    _renderer.position = [_position value];
#endif
}

- (IBAction)modeChanged:(id)sender
{
    _renderer.position = 1.0;
#if defined(TARGET_MACOS)
    [_position setFloatValue:1.0];
    _renderer.visibilityTestingMode = [_mode selectedSegment];
#elif defined(TARGET_IOS)
    [_position setValue:1.0];
    _renderer.visibilityTestingMode = [_mode selectedSegmentIndex];
#elif defined(TARGET_TVOS)
    _renderer.visibilityTestingMode = [_mode selectedSegmentIndex];
#endif
}

- (IBAction)toggleMode:(id)sender
{
    NSLog(@"received tap");
}

- (void) drawInMTKView:(nonnull MTKView*) view
{
#if defined(TARGET_TVOS)
    // The sample animates the position variable for lack of a slider control.
    _renderer.position = sin(CACurrentMediaTime() / 5.0);
#endif
    [_renderer drawInMTKView:view];

    // Set the label and value depending on the mode of the app.
    NSString* label = @"";
    NSString* value = @"";
    if(_renderer.visibilityTestingMode == AAPLFragmentCountingMode)
    {
        label = @"Fragment count:";
        value = [[NSString alloc] initWithFormat:@"%lu", _renderer.numVisibleFragments];
    }
    else if(_renderer.visibilityTestingMode == AAPLOcclusionCullingMode)
    {
        label = @"Spheres drawn:";
        value = [[NSString alloc] initWithFormat:@"%lu / %lu", _renderer.numSpheresDrawn, AAPLNumObjectsXYZ];
    }

#if defined(TARGET_MACOS)
    [_modeDisplay setStringValue:label];
    [_numDisplay setStringValue:value];
#elif defined(TARGET_IOS) || defined(TARGET_TVOS)
    [_modeDisplay setText:label];
    [_numDisplay setText:value];
#endif
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    [_renderer drawableSizeWillChange:view.bounds.size];
}

@end
