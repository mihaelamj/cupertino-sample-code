/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the renderer class which performs Metal setup and per frame rendering for a
traditional deferred renderer used for macOS and the iOS & tvOS simulators
*/

#import "AAPLRenderer_TraditionalDeferred.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "AAPLShaderTypes.h"

@implementation AAPLRenderer_TraditionalDeferred
{
    id <MTLRenderPipelineState> _lightPipelineState;

    MTLRenderPassDescriptor *_GBufferRenderPassDescriptor;
    MTLRenderPassDescriptor *_finalRenderPassDescriptor;
}

/// Perform traditional deferred renderer specific initialization
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view
{
    self = [super initWithMetalKitView:view];

    if(self)
    {
        self.singlePassDeferred = NO;
        [self loadMetal];
        [self loadScene];
    }

    return self;
}

/// Create traditional deferred renderer specific Metal state objects
- (void)loadMetal
{
    [super loadMetal];

    NSError *error;

    id <MTLLibrary> shaderLibrary = self.shaderLibrary;

    #pragma mark Point light render pipeline setup
    {
        MTLRenderPipelineDescriptor * renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = self.view.colorPixelFormat;

        // Enable additive blending
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].blendingEnabled = YES;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].rgbBlendOperation = MTLBlendOperationAdd;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].alphaBlendOperation = MTLBlendOperationAdd;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].destinationRGBBlendFactor = MTLBlendFactorOne;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].destinationAlphaBlendFactor = MTLBlendFactorOne;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].sourceRGBBlendFactor = MTLBlendFactorOne;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].sourceAlphaBlendFactor = MTLBlendFactorOne;

        renderPipelineDescriptor.depthAttachmentPixelFormat = self.view.depthStencilPixelFormat;
        renderPipelineDescriptor.stencilAttachmentPixelFormat = self.view.depthStencilPixelFormat;

        id <MTLFunction> lightVertexFunction = [shaderLibrary newFunctionWithName:@"deferred_point_lighting_vertex"];
        id <MTLFunction> lightFragmentFunction = [shaderLibrary newFunctionWithName:@"deferred_point_lighting_fragment_traditional"];

        renderPipelineDescriptor.label = @"Light";
        renderPipelineDescriptor.vertexFunction = lightVertexFunction;
        renderPipelineDescriptor.fragmentFunction = lightFragmentFunction;
        _lightPipelineState = [self.device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                      error:&error];

        NSAssert(_lightPipelineState, @"Failed to create lighting render pipeline state: %@", error);
    }

    #pragma mark GBuffer render pass descriptor setup
    // Create a render pass descriptor to create an encoder for rendering to the GBuffers.
    // The encoder stores rendered data of each attachment when encoding ends.
    _GBufferRenderPassDescriptor = [MTLRenderPassDescriptor new];

    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetLighting].loadAction = MTLLoadActionDontCare;
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetLighting].storeAction = MTLStoreActionDontCare;
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].loadAction = MTLLoadActionDontCare;
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].storeAction = MTLStoreActionStore;
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].loadAction = MTLLoadActionDontCare;
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].storeAction = MTLStoreActionStore;
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].loadAction = MTLLoadActionDontCare;
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].storeAction = MTLStoreActionStore;
    _GBufferRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
    _GBufferRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    _GBufferRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;

    _GBufferRenderPassDescriptor.stencilAttachment.clearStencil = 0;
    _GBufferRenderPassDescriptor.stencilAttachment.loadAction = MTLLoadActionClear;
    _GBufferRenderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionStore;

    // Create a render pass descriptor for thelighting and composition pass
    _finalRenderPassDescriptor = [MTLRenderPassDescriptor new];

    // Whatever rendered in the final pass needs to be stored so it can be displayed
    _finalRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    _finalRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionLoad;
    _finalRenderPassDescriptor.stencilAttachment.loadAction = MTLLoadActionLoad;
}

/// MTKViewDelegate Callback: Respond to device orientation change or other view size change
- (void) mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    // The renderer base class allocates all GBuffers >except< lighting GBuffer (since with the
    // single-pass deferred renderer the lighting buffer is the same as the drawable)
    [self drawableSizeWillChange:size withGBufferStorageMode:MTLStorageModePrivate];

    // Re-set GBuffer textures in the GBuffer render pass descriptor after they have been
    // reallocated by a resize
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].texture = self.albedo_specular_GBuffer;
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].texture = self.normal_shadow_GBuffer;
    _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].texture = self.depth_GBuffer;

    // Cannot set the depth stencil texture here since MTKView reallocates it *after* the
    // drawableSizeWillChange callback

    if(view.paused)
    {
        [view draw];
    }
}



/// Draw directional lighting, which, with a tradition deferred renderer needs to set GBuffers as
/// textures before executing common rendering code to draw the light
- (void)drawDirectionalLight:(nonnull id <MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder pushDebugGroup:@"Draw Directional Light"];
    [renderEncoder setFragmentTexture:self.albedo_specular_GBuffer atIndex:AAPLRenderTargetAlbedo];
    [renderEncoder setFragmentTexture:self.normal_shadow_GBuffer atIndex:AAPLRenderTargetNormal];
    [renderEncoder setFragmentTexture:self.depth_GBuffer atIndex:AAPLRenderTargetDepth];

    [super drawDirectionalLightCommon:renderEncoder];

    [renderEncoder popDebugGroup];
}

/// Setup tradition deferred rendering specific pipeline and set GBuffer textures. Then call common
/// renderer code to apply the point lights
- (void) drawPointLights:(id<MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder pushDebugGroup:@"Draw Point Lights"];

    [renderEncoder setRenderPipelineState:_lightPipelineState];

    [renderEncoder setFragmentTexture:self.albedo_specular_GBuffer atIndex:AAPLRenderTargetAlbedo];
    [renderEncoder setFragmentTexture:self.normal_shadow_GBuffer atIndex:AAPLRenderTargetNormal];
    [renderEncoder setFragmentTexture:self.depth_GBuffer atIndex:AAPLRenderTargetDepth];

    // Call common base class method after setting state in the renderEncoder specific to the
    // traditional deferred renderer
    [super drawPointLightsCommon:renderEncoder];

    [renderEncoder popDebugGroup];
}

/// MTKViewDelegate callback: Called whenever the view needs to render
- (void)drawSceneToView:(nonnull MTKView *)view
{
    id<MTLCommandBuffer> commandBuffer = [self beginFrame];
    commandBuffer.label = @"Shadow & GBuffer Commands";

    [super drawShadow:commandBuffer];

    _GBufferRenderPassDescriptor.depthAttachment.texture = self.view.depthStencilTexture;
    _GBufferRenderPassDescriptor.stencilAttachment.texture = self.view.depthStencilTexture;

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_GBufferRenderPassDescriptor];
    renderEncoder.label = @"GBuffer Generation";

    [super drawGBuffer:renderEncoder];

    [renderEncoder endEncoding];

    // Commit commands so that Metal can begin working on non-drawable dependant work without
    // waiting for a drawable to become avaliable
    [commandBuffer commit];

    commandBuffer = [self beginDrawableCommands];
    commandBuffer.label = @"Lighting Commands";

    id<MTLTexture> drawableTexture = self.currentDrawableTexture;

    // The final pass can only render if a drawable is available, otherwise it needs to skip
    // rendering this frame.
    if(drawableTexture)
    {
        // Render the lighting and composition pass

        _finalRenderPassDescriptor.colorAttachments[0].texture = drawableTexture;
        _finalRenderPassDescriptor.depthAttachment.texture = self.view.depthStencilTexture;
        _finalRenderPassDescriptor.stencilAttachment.texture = self.view.depthStencilTexture;

        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_finalRenderPassDescriptor];
        renderEncoder.label = @"Lighting & Composition Pass";

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
    if(self.bufferExaminationManager.mode )
    {
        // Clear the background of the GBuffer when examining buffers.  When rendering normally
        // clearing is wasteful, but when examining the buffers, the backgrounds appear corrupt
        // making unclear what's actually rendered to the buffers
        _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].loadAction = MTLLoadActionClear;
        _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].loadAction = MTLLoadActionClear;
        _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].loadAction = MTLLoadActionClear;

        // Store depth and stencil buffers after filling them.  This is wasteful when rendering
        // normally, but necessary to present the light mask culling view.
        _finalRenderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionStore;
        _finalRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
    }
    else
    {
        // When exiting buffer examination mode, return to efficient state settings
        _finalRenderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionDontCare;
        _finalRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
        _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetAlbedo].loadAction = MTLLoadActionDontCare;
        _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetNormal].loadAction = MTLLoadActionDontCare;
        _GBufferRenderPassDescriptor.colorAttachments[AAPLRenderTargetDepth].loadAction = MTLLoadActionDontCare;
    }
}

#endif // END SUPPORT_BUFFER_EXAMINATION

@end

