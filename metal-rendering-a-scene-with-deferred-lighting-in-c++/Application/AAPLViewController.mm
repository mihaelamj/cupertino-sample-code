/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the cross-platform view controller
*/

#import "AAPLViewController.h"
#import "../Renderer/Shaders/AAPLConfig.h"

#include "AAPLRenderer_TraditionalDeferred.h"
#include "AAPLRenderer_SinglePassDeferred.h"

#include "AAPLViewAdapter.h"

@implementation AAPLViewController
{
    __weak IBOutlet MTKView* _view;

    Renderer* _pRenderer;

    MTL::Device* _pDevice;

#if SUPPORT_BUFFER_EXAMINATION
    BufferExaminationManager *_bufferExaminationManager;

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
#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _pDevice = MTL::CreateSystemDefaultDevice();

    NSAssert(_pDevice, @"Metal is not supported on this device");

    // Set the view to use the default device
    MTKView *mtkView = (MTKView *)self.view;

    mtkView.device = (__bridge id<MTLDevice>)_pDevice;
    mtkView.delegate = self;

    bool useSinglePassDeferred = false;
#if TARGET_MACOS
    if(_pDevice->supportsFamily(MTL::GPUFamilyApple1))
    {
        useSinglePassDeferred = true;
    }
#elif !TARGET_OS_SIMULATOR
    // For iOS or tvOS targets, the sample chooses the single-pass deferred renderer.  Simulator
    // devices do not support features required to run  the single pass deferred renderer, so the
    // app must use the traditional deferred renderer on the simulator.
    useSinglePassDeferred = true;
#endif

    if(useSinglePassDeferred)
    {
        _pRenderer = new Renderer_SinglePassDeferred( _pDevice );
    }
    else
    {
        _pRenderer = new Renderer_TraditionalDeferred( _pDevice );
    }
    
    _view.depthStencilPixelFormat = (MTLPixelFormat)_pRenderer->depthStencilTargetPixelFormat();
    _view.colorPixelFormat = (MTLPixelFormat)_pRenderer->colorTargetPixelFormat();

    NSAssert(_pRenderer, @"Renderer failed initialization");

    CGSize size = _view.drawableSize;
    _pRenderer->drawableSizeWillChange( MTL::Size::Make(size.width, size.height, 0), MTL::StorageModePrivate);

#if SUPPORT_BUFFER_EXAMINATION
    
    NSArray<MTKView *>* views = @[
        _albedoGBufferView,
        _normalsGBufferView,
        _depthGBufferView,
        _shadowGBufferView,
        _finalFrameView,
        _specularGBufferView,
        _shadowMapView,
        _lightMaskView,
        _lightCoverageView
    ];
    
    for ( MTKView* mtkView in views )
    {
        [self _setupView:mtkView withDevice:(__bridge id<MTLDevice>)_pDevice];
    }

    AAPLViewAdapter rendererView( (__bridge void *)_view );
    _bufferExaminationManager = new BufferExaminationManager(*_pRenderer,
                                                             AAPLViewAdapter( (__bridge void *)_albedoGBufferView ),
                                                             AAPLViewAdapter( (__bridge void *)_normalsGBufferView ),
                                                             AAPLViewAdapter( (__bridge void *)_depthGBufferView ),
                                                             AAPLViewAdapter( (__bridge void *)_shadowGBufferView ),
                                                             AAPLViewAdapter( (__bridge void *)_finalFrameView ),
                                                             AAPLViewAdapter( (__bridge void *)_specularGBufferView ),
                                                             AAPLViewAdapter( (__bridge void *)_shadowMapView ),
                                                             AAPLViewAdapter( (__bridge void *)_lightMaskView ),
                                                             AAPLViewAdapter( (__bridge void *)_lightCoverageView ),
                                                             rendererView);

    auto [w, h] = _view.drawableSize;
    _bufferExaminationManager->updateDrawableSize( MTL::Size::Make( w, h, 0 ) );

    _pRenderer->bufferExaminationManager( _bufferExaminationManager );

#endif

}

- (void)_setupView:(MTKView *)mtkView withDevice:(id<MTLDevice>)device
{
    mtkView.device = device;
    
    // Other setup steps can be implemented here
}

- (void)dealloc
{
    delete _pRenderer;
    _pDevice->release();

#if SUPPORT_BUFFER_EXAMINATION

    delete _bufferExaminationManager;
    _bufferExaminationManager = nullptr;

#endif
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    MTL::Size newSize = MTL::Size::Make(size.width, size.height, 0);
    _pRenderer->drawableSizeWillChange(newSize, MTL::StorageModePrivate);
    
    // The drawable changes its size after the view redraws itself.
    // If the user pauses the view, the renderer
    // must explicitly force the view to redraw itself, otherwise Core Animation will just stretch or squish
    // the drawable as the view changes sizes.
    if(_view.paused)
    {
        [_view draw];
    }

#if SUPPORT_BUFFER_EXAMINATION

    _bufferExaminationManager->updateDrawableSize( newSize );

#endif
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    _pRenderer->drawInView(_view.paused,
                           (__bridge MTL::Drawable *)_view.currentDrawable,
                           (__bridge MTL::Texture *)_view.depthStencilTexture);
}

#if TARGET_IOS

#if SUPPORT_BUFFER_EXAMINATION 
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    // Toggle buffer examination mode whenever a touch occurs

    if(_bufferExaminationManager->mode())
    {
        _bufferExaminationManager->mode( ExaminationModeDisabled );
    }
    else
    {
        _bufferExaminationManager->mode( ExaminationModeAll );
    }

    _pRenderer->validateBufferExaminationMode();
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

    // If there's alread a view filling the window, shrink it back
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

    ExaminationMode currentMode = _bufferExaminationManager->mode();

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
                _bufferExaminationManager->mode( ExaminationModeAll );
                break;
            case '2':
                _bufferExaminationManager->mode( ExaminationModeAlbedo );
                focusView = _albedoGBufferView;
                break;
            case '3':
                _bufferExaminationManager->mode( ExaminationModeNormals );
                focusView = _normalsGBufferView;
                break;
            case '4':
                _bufferExaminationManager->mode( ExaminationModeDepth );
                focusView = _depthGBufferView;
                break;
            case '5':
                _bufferExaminationManager->mode( ExaminationModeShadowGBuffer );
                focusView = _shadowGBufferView;
                break;
            case '6':
                _bufferExaminationManager->mode( ExaminationModeSpecular );
                focusView = _specularGBufferView;
                break;
            case '7':
                _bufferExaminationManager->mode( ExaminationModeShadowMap );
                focusView = _shadowMapView;
                break;
            case '8':
                _bufferExaminationManager->mode( ExaminationModeMaskedLightVolumes );
                focusView = _lightMaskView;
                break;
            case '9':
                _bufferExaminationManager->mode( ExaminationModeFullLightVolumes );
                focusView = _lightCoverageView;
                break;
            case '0':
                _bufferExaminationManager->mode( ExaminationModeDisabled );
                break;
#endif // SUPPORT_BUFFER_EXAMINATION
        }
    }

#if SUPPORT_BUFFER_EXAMINATION

    if(currentMode != _bufferExaminationManager->mode())
    {
        _pRenderer->validateBufferExaminationMode();
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
