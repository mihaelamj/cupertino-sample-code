/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller
*/

#import "AAPLViewController.h"

#import "AAPLRenderer_TraditionalDeferred.h"
#import "AAPLRenderer_SinglePassDeferred.h"

@implementation AAPLViewController
{
    MTKView *_view;

    AAPLRenderer *_renderer;

#if SUPPORT_BUFFER_EXAMINATION

    AAPLBufferExaminationManager *_bufferExaminationManager;

    __weak IBOutlet MTKView *_albedoGBufferView;
    __weak IBOutlet MTKView *_normalsGBufferView;
    __weak IBOutlet MTKView *_depthGBufferView;
    __weak IBOutlet MTKView *_shadowGBufferView;
    __weak IBOutlet MTKView *_finalFrameView;
    __weak IBOutlet MTKView *_specularGBufferView;
    __weak IBOutlet MTKView *_shadowMapView;
    __weak IBOutlet MTKView *_lightMaskView;
    __weak IBOutlet MTKView *_lightCoverageView;

#if TARGET_MACOS
    MTKView *_fillView;
    NSView *_placeHolderView;
#endif

#endif // SUPPORT_BUFFER_EXAMINATION
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Set the view to use the default device
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();

    NSAssert(device, @"Metal is not supported on this device");

    _view = (MTKView *)self.view;
    _view.device = device;

    BOOL useSinglePassDeferred = NO;

#if TARGET_MACOS
    if(@available( macOS 11, * ))
    {
        // On macOS, the MTLGPUFamilyApple1 enum is only avaliable on macOS 11.  On macOS 11 check
        // if running on an Apple Silicon GPU to use the single pass deferred renderer
        if([device supportsFamily:MTLGPUFamilyApple1])
        {
            useSinglePassDeferred = YES;
        }
    }
#elif !TARGET_OS_SIMULATOR
    // For iOS or tvOS targets, the sample chooses the single-pass deferred renderer.  Simulator
    // devices do not support features required to run the single pass deferred renderer, so the
    // app must use the traditional deferred renderer on the simulator.
    useSinglePassDeferred = YES;
#endif

    if(useSinglePassDeferred)
    {
        _renderer = [[AAPLRenderer_SinglePassDeferred alloc] initWithMetalKitView:_view];
    }
    else
    {
        _renderer = [[AAPLRenderer_TraditionalDeferred alloc] initWithMetalKitView:_view];
    }

    NSAssert(_renderer, @"Renderer failed initialization");

    [_renderer mtkView:_view drawableSizeWillChange:_view.drawableSize];

#if SUPPORT_BUFFER_EXAMINATION

    _bufferExaminationManager = [[AAPLBufferExaminationManager alloc] initWithRenderer:_renderer
                                                                     albedoGBufferView:_albedoGBufferView
                                                                    normalsGBufferView:_normalsGBufferView
                                                                      depthGBufferView:_depthGBufferView
                                                                     shadowGBufferView:_shadowGBufferView
                                                                        finalFrameView:_finalFrameView
                                                                   specularGBufferView:_specularGBufferView
                                                                          shadowMapView:_shadowMapView
                                                                         lightMaskView:_lightMaskView
                                                                     lightCoverageView:_lightCoverageView];

    [_bufferExaminationManager updateDrawableSize:_view.drawableSize];

    _renderer.bufferExaminationManager = _bufferExaminationManager;

#endif

    _view.delegate = self;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    [_renderer mtkView:view drawableSizeWillChange:size];
    [_bufferExaminationManager updateDrawableSize:size];
}

- (void)drawInMTKView:(MTKView *)view
{
    [_renderer drawSceneToView:view];
}

#if TARGET_IOS

#if SUPPORT_BUFFER_EXAMINATION

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // Toggle buffer examination mode whenever a touch occurs

    if(_bufferExaminationManager.mode)
    {
        _bufferExaminationManager.mode = AAPLExaminationModeDisabled;
    }
    else
    {
        _bufferExaminationManager.mode = AAPLExaminationModeAll;
    }

    [_renderer validateBufferExaminationMode];

}

#endif // END SUPPORT_BUFFER_EXAMINATION

- (BOOL)prefersHomeIndicatorAutoHidden
{
    return YES;
}

#elif TARGET_MACOS

- (void)viewDidAppear
{
    // Make the view controller the window's first responder so that it can handle the Key events
    [_view.window makeFirstResponder:self];
}

#if SUPPORT_BUFFER_EXAMINATION
-(void)fillWindowWithView:(MTKView*)view
{
    if(view == _fillView)
    {
        return;
    }

    // If there's already a view filling the window, shrink it back
    if(_fillView)
    {
        assert(_placeHolderView);
        _fillView.autoresizingMask = _placeHolderView.autoresizingMask;
        _fillView.frame = _placeHolderView.frame;
        _fillView = nil;
        [_placeHolderView removeFromSuperview];
        _placeHolderView = nil;
    }

    // If we're providing a new view to fill, enlarge it
    if(view)
    {
        assert(!_placeHolderView);
        assert(!_fillView);
        _placeHolderView = [NSView new];
        _placeHolderView.frame = view.frame;
        _placeHolderView.autoresizingMask = view.autoresizingMask;
        [_view addSubview:_placeHolderView];
        view.frame = _view.frame;
        view.autoresizingMask = (NSViewMinXMargin    |
                                 NSViewWidthSizable  |
                                 NSViewMaxXMargin    |
                                 NSViewMinYMargin    |
                                 NSViewHeightSizable |
                                 NSViewMaxYMargin);
        _fillView = view;
    }
}
#endif // SUPPORT_BUFFER_EXAMINATION

- (void)keyDown:(NSEvent *)event
{
#if SUPPORT_BUFFER_EXAMINATION

    AAPLExaminationMode currentMode = _bufferExaminationManager.mode;

    MTKView *focusView = nil;

#endif // SUPPORT_BUFFER_EXAMINATION

    NSString* characters = [event characters];

    for (uint32_t k = 0; k < characters.length; k++)
    {
        unichar key = [characters characterAtIndex:k];

        // When space pressed, toggle buffer examination mode
        switch(key)
        {
            // Pause/Un-pause with spacebar
            case ' ':
            {
                _view.paused = !_view.paused;
                break;
            }
#if SUPPORT_BUFFER_EXAMINATION
            // Enter/exit buffer examination mode with e or return key
            case '\r':
            case '1':
                _bufferExaminationManager.mode = AAPLExaminationModeAll;
                break;
            case '2':
                _bufferExaminationManager.mode = AAPLExaminationModeAlbedo;
                focusView = _albedoGBufferView;
                break;
            case '3':
                _bufferExaminationManager.mode = AAPLExaminationModeNormals;
                focusView = _normalsGBufferView;
                break;
            case '4':
                _bufferExaminationManager.mode = AAPLExaminationModeDepth;
                focusView = _depthGBufferView;
                break;
            case '5':
                _bufferExaminationManager.mode = AAPLExaminationModeShadowGBuffer;
                focusView = _shadowGBufferView;
                break;
            case '6':
                _bufferExaminationManager.mode = AAPLExaminationModeSpecular;
                focusView = _specularGBufferView;
                break;
            case '7':
                _bufferExaminationManager.mode = AAPLExaminationModeShadowMap;
                focusView = _shadowMapView;
                break;
            case '8':
                _bufferExaminationManager.mode = AAPLExaminationModeMaskedLightVolumes;
                focusView = _lightMaskView;
                break;
            case '9':
                _bufferExaminationManager.mode = AAPLExaminationModeFullLightVolumes;
                focusView = _lightCoverageView;
                break;
            case '0':
                _bufferExaminationManager.mode = AAPLExaminationModeDisabled;
                break;
#endif // SUPPORT_BUFFER_EXAMINATION
        }
    }

#if SUPPORT_BUFFER_EXAMINATION

    if(currentMode != _bufferExaminationManager.mode)
    {
        [_renderer validateBufferExaminationMode];
        [self fillWindowWithView:focusView];
    }

#endif // SUPPORT_BUFFER_EXAMINATION
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

#endif // END TARGET_MACOS

@end
