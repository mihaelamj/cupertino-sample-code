/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the renderer class which performs Metal setup and per frame rendering for a
 single pass deferred renderer used for iOS & tvOS devices
*/

#import "AAPLRenderer_SinglePassDeferred.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "AAPLShaderTypes.h"

@implementation AAPLRenderer_SinglePassDeferred
{
    id <MTLRenderPipelineState> _lightPipelineState;

    MTLRenderPassDescriptor *_viewRenderPassDescriptor;

    MTLStorageMode _GBufferStorageMode;

    MTKView *_view;
}

/// Perform single pass deferred renderer specific initialization
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view
{
    self = [super initWithMetalKitView:view];

    if(self)
    {
        _view = view;

        if (@available( macOS 11, * ))
        {
            _GBufferStorageMode = MTLStorageModeMemoryless;
        }

        self.singlePassDeferred = YES;
        [self loadMetal];
        [self loadScene];
    }

    return self;
}

/// Create Metal render state objects specific to the single pass deferred renderer
- (void)loadMetal
{
    [super loadMetal];

    NSError *error;

    id <MTLLibrary> shaderLibrary = self.shaderLibrary;

    #pragma mark Point light render pipeline setup
    {
        MTLRenderPipelineDescriptor * renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = self.view.colorPixelFormat;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetAlbedo].pixelFormat = self.albedo_specular_GBufferFormat;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetNormal].pixelFormat =  self.normal_shadow_GBufferFormat;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetDepth].pixelFormat =  self.depth_GBufferFormat;
        renderPipelineDescriptor.depthAttachmentPixelFormat =  self.view.depthStencilPixelFormat;
        renderPipelineDescriptor.stencilAttachmentPixelFormat =  self.view.depthStencilPixelFormat;

        id <MTLFunction> lightVertexFunction = [shaderLibrary newFunctionWithName:@"deferred_point_lighting_vertex"];
        id <MTLFunction> lightFragmentFunction = [shaderLibrary newFunctionWithName:@"deferred_point_lighting_fragment_single_pass"];

        renderPipelineDescriptor.label = @"Light";
        renderPipelineDescriptor.vertexFunction = lightVertexFunction;
        renderPipelineDescriptor.fragmentFunction = lightFragmentFunction;
        _lightPipelineState = [self.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                      error:&error];

        NSAssert(_lightPipelineState, @"Failed to create render pipeline state: %@", error);
    }

    #pragma mark GBuffer + View render pass descriptor setup
    _viewRenderPassDescriptor = [MTLRenderPassDescriptor new];
    _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].loadAction = MTLLoadActionDontCare;
    _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].storeAction = MTLStoreActionDontCare;
    _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].loadAction = MTLLoadActionDontCare;
    _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].storeAction = MTLStoreActionDontCare;
    _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].loadAction = MTLLoadActionDontCare;
    _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].storeAction = MTLStoreActionDontCare;
    _viewRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    _viewRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    _viewRenderPassDescriptor.stencilAttachment.loadAction = MTLLoadActionClear;
    _viewRenderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionDontCare;
    _viewRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
    _viewRenderPassDescriptor.stencilAttachment.clearStencil = 0;
}

/// MTKViewDelegate Callback: Respond to device orientation change or other view size change
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // The renderer base class allocates all GBuffers >except< lighting GBuffer (since with the
    // single-pass deferred renderer the lighting buffer is the same as the drawable)
    [super drawableSizeWillChange:size withGBufferStorageMode:_GBufferStorageMode];

    // Re-set GBuffer textures in the GBuffer render pass descriptor after they have been
    // reallocated by a resize
    _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].texture = self.albedo_specular_GBuffer;
    _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].texture = self.normal_shadow_GBuffer;
    _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].texture = self.depth_GBuffer;

    // Cannot set the depth stencil texture here since MTKView reallocates it *after* the
    // drawableSizeWillChange callback

    if(view.paused)
    {
        [view draw];
    }
}

/// Draw directional lighting, which, on with the single pass deferred renderer does not need
/// GBuffers set as textures as they do with the traditional deferred renderer
- (void)drawDirectionalLight:(nonnull id <MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder pushDebugGroup:@"Draw Directional Light"];

    [super drawDirectionalLightCommon:renderEncoder];

    [renderEncoder popDebugGroup];
}

/// Setup single pass deferred renderer specific pipeline/  Then call common renderer code to apply
/// the point lights
- (void) drawPointLights:(id<MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder pushDebugGroup:@"Draw Point Lights"];

    [renderEncoder setRenderPipelineState:_lightPipelineState];

    // Call common base class method after setting state in the renderEncoder specific to the
    // single-pass deferred renderer
    [super drawPointLightsCommon:renderEncoder];

    [renderEncoder popDebugGroup];
}

/// MTKViewDelegate callback: Called whenever the view needs to render
- (void)drawSceneToView:(nonnull MTKView *)view
{
    id<MTLCommandBuffer> commandBuffer = [self beginFrame];
    commandBuffer.label = @"Shadow commands";

    [super drawShadow:commandBuffer];

    // Commit commands so that Metal can begin working on non-drawable dependant work without
    // waiting for a drawable to become avaliable
    [commandBuffer commit];

    commandBuffer = [self beginDrawableCommands];
    commandBuffer.label = @"GBuffer & Lighting Commands";

    id<MTLTexture> drawableTexture = self.currentDrawableTexture;

    // The final pass can only render if a drawable is available, otherwise it needs to skip
    // rendering this frame.
    if(drawableTexture)
    {
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetLighting].texture = drawableTexture;
        _viewRenderPassDescriptor.depthAttachment.texture = self.view.depthStencilTexture;
        _viewRenderPassDescriptor.stencilAttachment.texture = self.view.depthStencilTexture;

        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_viewRenderPassDescriptor];
        renderEncoder.label = @"Combined GBuffer & Lighting Pass";

        [super drawGBuffer:renderEncoder];

        [self drawDirectionalLight:renderEncoder];

        [super drawPointLightMask:renderEncoder];

        [self drawPointLights:renderEncoder];

        [super drawSky:renderEncoder];

        [super drawFairies:renderEncoder];

        [renderEncoder endEncoding];
    }

    [self endFrame:commandBuffer];
}

#if SUPPORT_BUFFER_EXAMINATION
/// Enable (or disable) buffer examination mode
- (void)validateBufferExaminationMode
{
    // When in buffer examination mode, the renderer must allocate the GBuffers with
    // StorageModePrivate since the buffer examination manager needs the GBuffers written to main
    // memory to render them on screen later.
    // However, when a buffer examination mode is not enabled, the renderer only needs the GBuffers
    // in the GPU tile memory, so it can use StorageModeMemoryless to conserve memory.
    
    if(self.bufferExaminationManager.mode)
    {
        // Clear the background of the GBuffer when examining buffers.  When rendering normally
        // clearing is wasteful, but when examining the buffers, the backgrounds appear corrupt
        // making unclear what's actually rendered to the buffers
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].loadAction = MTLLoadActionClear;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].loadAction = MTLLoadActionClear;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].loadAction = MTLLoadActionClear;

        // Store results of all buffers to examine them.  This is wasteful when rendering
        // normally, but necessary to present them on screen.
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].storeAction = MTLStoreActionStore;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].storeAction = MTLStoreActionStore;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].storeAction = MTLStoreActionStore;
        _viewRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
        _viewRenderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionStore;

        _GBufferStorageMode = MTLStorageModePrivate;
    }
    else
    {
        // When exiting buffer examination mode, return to efficient state settings
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].loadAction = MTLLoadActionDontCare;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].loadAction = MTLLoadActionDontCare;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].loadAction = MTLLoadActionDontCare;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].storeAction = MTLStoreActionDontCare;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].storeAction = MTLStoreActionDontCare;
        _viewRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].storeAction = MTLStoreActionDontCare;
        _viewRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
        _viewRenderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionDontCare;

        if (@available( macOS 11, *))
        {
            _GBufferStorageMode = MTLStorageModeMemoryless;
        }
    }

    // Force reallocation of GBuffers since storage mode will have changed.
    [self mtkView:_view drawableSizeWillChange:_view.drawableSize];
}

#endif

@end
