/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The cross-platform view controller.
*/
#import "AAPLViewController.h"
#import "AAPLRenderer.h"

NSUInteger selectedSegmentOf(PlatformSegmentedControl* sender)
{
#if TARGET_IOS || TARGET_TVOS
    return sender.selectedSegmentIndex;
#elif TARGET_MACOS
    return sender.selectedSegment;
#endif
}
/// A declaration of a function pointer that returns a descriptive string from its enumeration integer value.
typedef NSString* (*getLabelFromEnum)(NSInteger);

@implementation AAPLViewController
{
    MTKView *_view;
    
    AAPLRenderer *_renderer;
    
    NSUInteger activeSampleCount;
    
    BOOL sampleCountSupported[AAPLSampleCountOptionsCount];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _view = (MTKView*)self.view;
    _view.device = MTLCreateSystemDefaultDevice();
    _view.delegate = self;
    
#if TARGET_TVOS
    // The app uses an 8-bit format on tvOS to illustrate output to an 8-bit framebuffer.
    _view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
#else
    _view.colorPixelFormat = MTLPixelFormatRGBA16Float;
#endif

    _renderer = [[AAPLRenderer alloc] initWithMetalDevice:_view.device
                                      drawablePixelFormat:_view.colorPixelFormat];
    [_renderer drawableSizeWillChange:_view.bounds.size];
    
    [self setupControls];
}

/// Sets up the control elements in the UI for the platform-specific view.
///
/// This includes the onscreen labels, buttons, etc., and the input sources including tap gestures, the keyboard, and Siri or Apple TV Remote key events.
- (void)setupControls
{
    // Use darker appearance to highlight UI control elements.
    [self applyDarkAppearance];
    
    [self setupAnimationControl];
    
    NSUInteger sampleCounts[AAPLSampleCountOptionsCount] = { 2, 4, 8 };
    for (int i = 0; i < AAPLSampleCountOptionsCount; i++)
    {
        sampleCountSupported[i] = [_view.device supportsTextureSampleCount:sampleCounts[i]];
    }

    [self setupSegments:_antialiasingResolveOptionSegments
              enumCount:AAPLResolveOptionOptionsCount
          labelFunction:getLabelForAAPLResolveOption
         initialSegment:AAPLResolveOptionBuiltin
            mapToEnable:nil];
    
    __unsafe_unretained typeof(self) altSelf = self;
    
    [self setupSegments:_antialiasingSampleCountSegments
              enumCount:AAPLSampleCountOptionsCount
          labelFunction:getLabelForAAPLSampleCount
         initialSegment:AAPLSampleCountFour
            mapToEnable:^BOOL(NSInteger index) {
        return altSelf->sampleCountSupported[index];
    }];
    
    [self setupSegments:_resolvePathSegments
              enumCount:AAPLResolveKernelPathOptionsCount
          labelFunction:getLabelForAAPLResolveKernelPath
         initialSegment:AAPLResolveKernelPathImmediate
            mapToEnable:^BOOL(NSInteger index) {
        switch (index) {
            case AAPLResolveKernelPathImmediate:
                return YES;
            case AAPLResolveKernelPathTileBased:
                return altSelf->_renderer.supportsTileShaders;
            default:
                return NO;
        }
    }];
    
    [self setupSegments:_renderingQualitySegments
              enumCount:AAPLRenderingQualityOptionsCount
          labelFunction:getLabelForAAPLRenderingQuality
         initialSegment:AAPLRenderingQualityOriginal
            mapToEnable:nil];
}

- (void)applyDarkAppearance
{
#if TARGET_IOS || TARGET_TVOS
    [_view setOverrideUserInterfaceStyle:UIUserInterfaceStyleDark];
#elif TARGET_MACOS
    NSAppearance *appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    [_view setAppearance:appearance];
#endif
}

- (void)setupAnimationControl
{
#if TARGET_IOS || TARGET_TVOS
    // On iOS, tap on the scene to toggle animation,
    // and on tvOS, press the Play/Pause button on Siri Remote or Apple TV Remote.
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(toggleAnimation)];
#if TARGET_TVOS
    [tapGesture setAllowedPressTypes:@[[NSNumber numberWithInteger:UIPressTypePlayPause]]];
#endif
    [self.view addGestureRecognizer:tapGesture];
    
    // Respond to space bar presses on a physical keyboard connected to the device.
    UIKeyCommand *keyCommand = [UIKeyCommand keyCommandWithInput:@" "
                                                   modifierFlags:0
                                                          action:@selector(toggleAnimation)];
    [self addKeyCommand:keyCommand];
#elif TARGET_MACOS
    // On macOS, the sample uses the `keyDown:` event.
#endif
}

- (void)setupSegments:(PlatformSegmentedControl*)segments
            enumCount:(NSInteger)count
        labelFunction:(getLabelFromEnum)labelFunction
       initialSegment:(NSInteger)initialSegment
          mapToEnable:(BOOL (^)(NSInteger index))mapFunction
{
#if TARGET_IOS || TARGET_TVOS
    [segments removeAllSegments];
    for (NSInteger i = 0; i < count; i++)
    {
        [segments insertSegmentWithTitle:labelFunction(i)
                                 atIndex:i
                                animated:NO];
        if (mapFunction && !mapFunction(i))
        {
            [segments setEnabled:NO forSegmentAtIndex:i];
        }
    }
    [segments setSelectedSegmentIndex:initialSegment];
#elif TARGET_MACOS
    [segments setSegmentCount:count];
    for (NSInteger i = 0; i < count; i++)
    {
        [segments setLabel:labelFunction(i)
                forSegment:i];
        
        if (mapFunction && !mapFunction(i))
        {
            [segments setEnabled:NO forSegment:i];
        }
    }
    [segments setSelectedSegment:initialSegment];
#endif
}

#pragma mark - MTKView Delegate

- (void)drawInMTKView:(nonnull MTKView*)view
{
    [_renderer drawInMTKView:view];
}

- (void)mtkView:(nonnull MTKView*)view drawableSizeWillChange:(CGSize)size
{
    [_renderer drawableSizeWillChange:view.bounds.size];
}

#pragma mark - UI Actions

- (IBAction)toggleAntialiasing:(PlatformButton*)sender
{
#if TARGET_IOS
    [_renderer setAntialiasingEnabled:sender.on];
    
    [UIView transitionWithView:_msaaOptionsGroupView
                      duration:0.2
                       options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
        self->_msaaOptionsGroupView.alpha = sender.on ? 1.0 : 0.0;
    }
                    completion:nil];
    
#elif TARGET_TVOS
    [_renderer setAntialiasingEnabled:!_renderer.antialiasingEnabled];
    
    [UIView transitionWithView:_msaaOptionsGroupView
                      duration:0.2
                       options:UIViewAnimationOptionCurveEaseInOut
                    animations:^{
        self->_msaaOptionsGroupView.alpha = self->_renderer.antialiasingEnabled ? 1.0 : 0.0;
    }
                    completion:nil];
    
    [self updateMSAAIndicatorOnTV];
    
#elif TARGET_MACOS
    [_renderer setAntialiasingEnabled:sender.state];
    
    [[_msaaOptionsGroupView animator] setAlphaValue: sender.state ? 1.0 : 0.0];
#endif
    
    [_renderer setAntialiasingOptionsChanged:YES];
}

- (void)toggleAnimation
{
    _renderer.animated = !_renderer.animated;
}

- (IBAction)updateAntialiasingSampleCount:(PlatformSegmentedControl*)sender
{
    [_renderer setAntialiasingSampleCount:lookupSampleCount(selectedSegmentOf(sender))];
    [_renderer setAntialiasingOptionsChanged:YES];
}

- (IBAction)updateAntialiasingResolve:(PlatformSegmentedControl*)sender
{
    [_renderer setResolveOption:selectedSegmentOf(sender)];
    [_renderer setAntialiasingOptionsChanged:YES];
}

- (IBAction)changeRenderingQuality:(PlatformSegmentedControl*)sender
{
    _renderer.renderingQuality = lookupQualityFactor(selectedSegmentOf(sender));
    [_renderer drawableSizeWillChange:_view.drawableSize];
}

- (IBAction)changeResolvePath:(PlatformSegmentedControl*)sender
{
    BOOL state = (selectedSegmentOf(sender) == AAPLResolveKernelPathTileBased);
    [_renderer setResolvingOnTileShaders:state];
    [_renderer setAntialiasingOptionsChanged:YES];
}

#pragma mark - Event handling

#if TARGET_MACOS

/// Toggles the animation with the space bar on macOS.
- (void)keyDown:(NSEvent*)event
{
    if (event.keyCode == kVK_Space)
    {
        [self toggleAnimation];
    }
}

#endif

#pragma mark - Helpers

#if TARGET_TVOS
- (void)updateMSAAIndicatorOnTV
{
    UIImage *symbolImage = [UIImage systemImageNamed:_renderer.antialiasingEnabled ? @"checkmark.circle.fill" : @"circle"];
    
    [_antialasingToggle setImage:symbolImage
                        forState:UIControlStateNormal];
}
#endif

@end
