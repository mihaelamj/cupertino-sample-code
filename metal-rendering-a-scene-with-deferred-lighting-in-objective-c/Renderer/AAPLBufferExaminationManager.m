  /*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of renderer class which performs Metal setup and per frame rendering
*/
#import "AAPLBufferExaminationManager.h"

#if SUPPORT_BUFFER_EXAMINATION

#import "AAPLShaderTypes.h"
#import "AAPLRenderer.h"

@import simd;
@import MetalKit;

#if TARGET_MACOS
#define ColorClass NSColor
#define MakeRect NSMakeRect
#else
#define ColorClass UIColor
#define MakeRect CGRectMake
#endif

@implementation AAPLBufferExaminationManager
{
    id<MTLDevice> _device;

    // Pipeline state used to visualize the point light volume coverage and stencil
    // culled light volume coverage
    id <MTLRenderPipelineState> _lightVolumeVisualizationPipelineState;
    id <MTLRenderPipelineState> _textureDepthPipelineState;
    id <MTLRenderPipelineState> _textureRGBPipelineState;
    id <MTLRenderPipelineState> _textureAlphaPipelineState;
    id <MTLDepthStencilState> _depthTestOnlyDepthStencilState;

    __weak AAPLRenderer * _renderer;

    AAPLExaminationMode _mode;

    MTKView *_albedoGBufferView;
    MTKView *_normalsGBufferView;
    MTKView *_depthGBufferView;
    MTKView *_shadowGBufferView;
    MTKView *_finalFrameView;
    MTKView *_specularGBufferView;
    MTKView *_shadowMapView;
    MTKView *_lightMaskView;
    MTKView *_lightCoverageView;

    id<MTLTexture> _lightVolumeTarget;

    NSSet<MTKView*> *_allViews;
}

- (nonnull instancetype)initWithRenderer:(nonnull AAPLRenderer *)renderer
                       albedoGBufferView:(nonnull MTKView*)albedoGBufferView
                      normalsGBufferView:(nonnull MTKView*)normalsGBufferView
                        depthGBufferView:(nonnull MTKView*)depthGBufferView
                       shadowGBufferView:(nonnull MTKView*)shadowGBufferView
                          finalFrameView:(nonnull MTKView*)finalFrameView
                     specularGBufferView:(nonnull MTKView*)specularGBufferView
                           shadowMapView:(nonnull MTKView*)shadowMapView
                           lightMaskView:(nonnull MTKView*)lightMaskView
                       lightCoverageView:(nonnull MTKView*)lightCoverageView
{
    self = [super init];
    if(self)
    {
        _renderer = renderer;
        _device = renderer.device;

        _albedoGBufferView   = albedoGBufferView;
        _normalsGBufferView  = normalsGBufferView;
        _depthGBufferView    = depthGBufferView;
        _shadowGBufferView   = shadowGBufferView;
        _finalFrameView      = finalFrameView;
        _specularGBufferView = specularGBufferView;
        _shadowMapView       = shadowMapView;
        _lightMaskView       = lightMaskView;
        _lightCoverageView   = lightCoverageView;

        _allViews = [[NSSet alloc] initWithArray:
                     @[
                         _albedoGBufferView,
                         _normalsGBufferView,
                         _depthGBufferView,
                         _shadowGBufferView,
                         _finalFrameView,
                         _specularGBufferView,
                         _shadowMapView,
                         _lightMaskView,
                         _lightCoverageView
                      ]];


        for(MTKView *view in _allViews)
        {
            // "Pause" the view since the BufferExaminationManager explicitly trigger's redraw in
            //   -[AAPLBufferExaminationManager drawAndPresentBuffersWithCommandBuffer:]
            view.paused = YES;

            // Initialize other properties
            view.device = _device;
            view.colorPixelFormat = _renderer.colorTargetPixelFormat;
            view.hidden = YES;
        }

        [self loadMetalState];
    }
    return self;
}

- (void) loadMetalState
{
    NSError *error;

    id <MTLLibrary> shaderLibrary = _renderer.shaderLibrary;

    #pragma mark Light volume visulalization render pipeline setup
    {
        id <MTLFunction> vertexFunction = [shaderLibrary newFunctionWithName:@"light_volume_visualization_vertex"];
        id <MTLFunction> fragmentFunction = [shaderLibrary newFunctionWithName:@"light_volume_visualization_fragment"];

        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];

        renderPipelineDescriptor.label = @"Light Volume Visualization";
        renderPipelineDescriptor.vertexDescriptor = nil;
        renderPipelineDescriptor.vertexFunction = vertexFunction;
        renderPipelineDescriptor.fragmentFunction = fragmentFunction;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = _renderer.colorTargetPixelFormat;
        renderPipelineDescriptor.depthAttachmentPixelFormat = _renderer.depthStencilTargetPixelFormat;
        renderPipelineDescriptor.stencilAttachmentPixelFormat = _renderer.depthStencilTargetPixelFormat;

        _lightVolumeVisualizationPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                                         error:&error];

        NSAssert(_lightVolumeVisualizationPipelineState,
                 @"Failed to create light volume visualization render pipeline state: %@",
                 error);
    }

    #pragma mark Raw GBuffer visualization pipeline setup
    // Set up pipelines to display raw GBuffers
    {
        id <MTLFunction> vertexFunction = [shaderLibrary newFunctionWithName:@"texture_values_vertex"];
        id <MTLFunction> fragmentFunction = [shaderLibrary newFunctionWithName:@"texture_rgb_fragment"];

        // Create simple pipelines that either render RGB or Alpha component of a texture
        MTLRenderPipelineDescriptor *renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];

        renderPipelineDescriptor.label = @"Light Volume Visualization";
        renderPipelineDescriptor.vertexDescriptor = nil;
        renderPipelineDescriptor.vertexFunction = vertexFunction;
        renderPipelineDescriptor.fragmentFunction = fragmentFunction;
        renderPipelineDescriptor.colorAttachments[AAPLRenderTargetLighting].pixelFormat = _renderer.colorTargetPixelFormat;

        // Pipeline to render RGB components of a texture
        _textureRGBPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                             error:&error];

        NSAssert(_textureRGBPipelineState,
                 @"Failed to create texture RGB render pipeline state: %@",
                 error);

        // Pipeline to render Alpha components of a texture (in RGB as grayscale)
        fragmentFunction = [shaderLibrary newFunctionWithName:@"texture_alpha_fragment"];
        renderPipelineDescriptor.fragmentFunction = fragmentFunction;
        _textureAlphaPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                               error:&error];

        NSAssert(_textureAlphaPipelineState,
                 @"Failed to create texture alpha render pipeline state: %@", error);

        // Pipeline to render Alpha components of a texture (in RGB as grayscale), but with the
        // ability to apply a range with which to divide the alpha value by so that grayscale value
        // is normalized from 0-1
        fragmentFunction = [shaderLibrary newFunctionWithName:@"texture_depth_fragment"];
        renderPipelineDescriptor.fragmentFunction = fragmentFunction;
        _textureDepthPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor
                                                                             error:&error];

        NSAssert(_textureDepthPipelineState,
                 @"Failed to create depth texture render pipeline state: %@", error);
    }

    #pragma mark Light volume visulalization depth state setup
    {
        MTLDepthStencilDescriptor *depthStencilDesc = [MTLDepthStencilDescriptor new];
        depthStencilDesc.depthWriteEnabled = NO;
        depthStencilDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        depthStencilDesc.label = @"Depth Test Only";

        _depthTestOnlyDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];
    }
}

- (void)updateDrawableSize:(CGSize)size
{
    MTLTextureDescriptor *finalTextureDesc =
        [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_renderer.colorTargetPixelFormat
                                                           width:size.width
                                                          height:size.height
                                                       mipmapped:NO];

    finalTextureDesc.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;

    if(_mode)
    {
        _offscreenDrawable = [_device newTextureWithDescriptor:finalTextureDesc];
        _offscreenDrawable.label = @"Offscreen Drawable";
    }
    else
    {
        _offscreenDrawable = nil;
    }

    if(_mode & (AAPLExaminationModeMaskedLightVolumes | AAPLExaminationModeFullLightVolumes))
    {
        _lightVolumeTarget = [_device newTextureWithDescriptor:finalTextureDesc];
        _lightVolumeTarget.label = @"Light Volume Drawable";
    }
    else
    {
        _lightVolumeTarget = nil;
    }
}


/// Draws icosahedrons encapsulating the pointLight volumes in *red*. This shows the fragments the
/// point light fragment shader would need to execute if culling were not enabled.  If light
/// culling is enabled. the fragments drawn when culling enabled are colored *green* allowing
/// user to compare the coverage
- (void) renderLightVolumesExaminationWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
                                            fullVolumes:(BOOL)fullVolumes
{
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].texture = _lightVolumeTarget;
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

    {
        id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"Stenciled light volumes background";

        // First draw the final fully composited scene as the background
        [renderEncoder setRenderPipelineState:_textureRGBPipelineState];
        [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
        [renderEncoder setFragmentTexture:_offscreenDrawable atIndex:AAPLTextureIndexBaseColor];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        [renderEncoder endEncoding];
    }

    renderPassDescriptor.depthAttachment.texture = _renderer.depthStencilTexture;
    renderPassDescriptor.stencilAttachment.texture = _renderer.depthStencilTexture;
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
    renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionLoad;
    renderPassDescriptor.stencilAttachment.loadAction = MTLLoadActionLoad;

    {
        id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"Stenciled light volumes";

        // Set simple pipeline which just draws a single color
        [renderEncoder setRenderPipelineState:_lightVolumeVisualizationPipelineState];
        [renderEncoder setVertexBuffer:_renderer.frameDataBuffers[_renderer.frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexFrameData];
        [renderEncoder setVertexBuffer:_renderer.lightsData offset:0 atIndex:AAPLBufferIndexLightsData];
        [renderEncoder setVertexBuffer:_renderer.lightPositions[_renderer.frameDataBufferIndex] offset:0 atIndex:AAPLBufferIndexLightsPosition];
        MTKMeshBuffer *vertexBuffer = _renderer.icosahedronMesh.vertexBuffers[AAPLBufferIndexMeshPositions];
        [renderEncoder setVertexBuffer:vertexBuffer.buffer offset:vertexBuffer.offset atIndex:AAPLBufferIndexMeshPositions];

        MTKSubmesh *icosahedronSubmesh = _renderer.icosahedronMesh.submeshes[0];

        if(fullVolumes || !LIGHT_STENCIL_CULLING)
        {
            // Set depth stencil state that uses stencil test to cull fragments
            [renderEncoder setDepthStencilState:_depthTestOnlyDepthStencilState];

            // Set red color to output in fragment function
            vector_float4 redColor = { 1, 0, 0, 1 };
            [renderEncoder setFragmentBytes:&redColor length:sizeof(redColor) atIndex:AAPLBufferIndexFlatColor];

            [renderEncoder drawIndexedPrimitives:icosahedronSubmesh.primitiveType
                                      indexCount:icosahedronSubmesh.indexCount
                                       indexType:icosahedronSubmesh.indexType
                                     indexBuffer:icosahedronSubmesh.indexBuffer.buffer
                               indexBufferOffset:icosahedronSubmesh.indexBuffer.offset
                                   instanceCount:AAPLNumLights];
        }

#if LIGHT_STENCIL_CULLING
        // Set green color to output in fragment function
        vector_float4 greenColor = { 0, 1, 0, 1 };
        [renderEncoder setFragmentBytes:&greenColor length:sizeof(greenColor) atIndex:AAPLBufferIndexFlatColor];

        // Set depth stencil state that uses stencil test to cull fragments
        [renderEncoder setDepthStencilState:_renderer.pointLightDepthStencilState];

        [renderEncoder setCullMode:MTLCullModeBack];

        [renderEncoder setStencilReferenceValue:128];


        // Draw volumes with stencil mask enabled (in green)
        [renderEncoder drawIndexedPrimitives:icosahedronSubmesh.primitiveType
                                  indexCount:icosahedronSubmesh.indexCount
                                   indexType:icosahedronSubmesh.indexType
                                 indexBuffer:icosahedronSubmesh.indexBuffer.buffer
                           indexBufferOffset:icosahedronSubmesh.indexBuffer.offset
                               instanceCount:AAPLNumLights];
#endif // END LIGHT_STENCIL_CULLING

        [renderEncoder endEncoding];
    }


}

- (void)drawAlbedoGBufferWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_albedoGBufferView.currentRenderPassDescriptor];
    renderEncoder.label = @"drawAlbedoGBufferWithCommandBuffer";
    [renderEncoder setRenderPipelineState:_textureRGBPipelineState];
    [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setFragmentTexture:_renderer.albedo_specular_GBuffer atIndex:AAPLTextureIndexBaseColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderEncoder endEncoding];
    [_albedoGBufferView draw];
}

- (void)drawNormalsGBufferWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_normalsGBufferView.currentRenderPassDescriptor];
    renderEncoder.label = @"drawNormalsGBufferWithCommandBuffer";
    [renderEncoder setRenderPipelineState:_textureRGBPipelineState];
    [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setFragmentTexture:_renderer.normal_shadow_GBuffer atIndex:AAPLTextureIndexBaseColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderEncoder endEncoding];
}

- (void)drawDepthGBufferWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_depthGBufferView.currentRenderPassDescriptor];
    renderEncoder.label = @"drawDepthGBufferWithCommandBuffer";
    [renderEncoder setRenderPipelineState:_textureDepthPipelineState];
    [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setFragmentTexture:_renderer.depth_GBuffer atIndex:AAPLTextureIndexBaseColor];
#if USE_EYE_DEPTH
    float depthRange = AAPLFarPlane - AAPLNearPlane;
#else
    float depthRange = 1.0;
#endif
    [renderEncoder setFragmentBytes:&depthRange length:sizeof(depthRange) atIndex:AAPLBufferIndexDepthRange];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderEncoder endEncoding];
}

- (void)drawShadowGBufferWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_shadowGBufferView.currentRenderPassDescriptor];
    renderEncoder.label = @"drawShadowGBufferWithCommandBuffer";
    [renderEncoder setRenderPipelineState:_textureAlphaPipelineState];
    [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setFragmentTexture:_renderer.normal_shadow_GBuffer atIndex:AAPLTextureIndexBaseColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderEncoder endEncoding];
}

- (void)drawFinalRenderWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_finalFrameView.currentRenderPassDescriptor];
    renderEncoder.label = @"drawFinalRenderWithCommandBuffer";
    [renderEncoder setRenderPipelineState:_textureRGBPipelineState];
    [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setFragmentTexture:_offscreenDrawable atIndex:AAPLTextureIndexBaseColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderEncoder endEncoding];
}


- (void)drawSpecularGBufferWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_specularGBufferView.currentRenderPassDescriptor];
    renderEncoder.label = @"drawSpecularGBufferWithCommandBuffer";
    [renderEncoder setRenderPipelineState:_textureAlphaPipelineState];
    [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setFragmentTexture:_renderer.albedo_specular_GBuffer atIndex:AAPLTextureIndexBaseColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderEncoder endEncoding];
}

- (void)drawShadowMapWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_shadowMapView.currentRenderPassDescriptor];
    renderEncoder.label = @"drawShadowMapWithCommandBuffer";
    float depthRange = 1.0;
    [renderEncoder setFragmentBytes:&depthRange length:sizeof(depthRange) atIndex:AAPLBufferIndexDepthRange];
    [renderEncoder setRenderPipelineState:_textureDepthPipelineState];
    [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setFragmentTexture:_renderer.shadowMap atIndex:AAPLTextureIndexBaseColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderEncoder endEncoding];
}

- (void)drawLightMaskWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    [self renderLightVolumesExaminationWithCommandBuffer:commandBuffer
                                             fullVolumes:NO];

    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_lightMaskView.currentRenderPassDescriptor];
    renderEncoder.label = @"drawLightMaskWithCommandBuffer";
    [renderEncoder setRenderPipelineState:_textureRGBPipelineState];
    [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setFragmentTexture:_lightVolumeTarget atIndex:AAPLTextureIndexBaseColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderEncoder endEncoding];
}

- (void)drawLightVolumesWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    [self renderLightVolumesExaminationWithCommandBuffer:commandBuffer
                                             fullVolumes:YES];

    id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_lightCoverageView.currentRenderPassDescriptor];
    renderEncoder.label = @"drawLightVolumesWithCommandBuffer";
    [renderEncoder setRenderPipelineState:_textureRGBPipelineState];
    [renderEncoder setVertexBuffer:_renderer.quadVertexBuffer offset:0 atIndex:AAPLBufferIndexMeshPositions];
    [renderEncoder setFragmentTexture:_lightVolumeTarget atIndex:AAPLTextureIndexBaseColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    [renderEncoder endEncoding];
}

- (void)setMode:(AAPLExaminationMode)mode
{
    _mode = mode;

    _finalFrameView.hidden      = !(_mode == AAPLExaminationModeAll);
    _albedoGBufferView.hidden   = !(_mode & AAPLExaminationModeAlbedo);
    _normalsGBufferView.hidden  = !(_mode & AAPLExaminationModeNormals);
    _depthGBufferView.hidden    = !(_mode & AAPLExaminationModeDepth);
    _shadowGBufferView.hidden   = !(_mode & AAPLExaminationModeShadowGBuffer);
    _specularGBufferView.hidden = !(_mode & AAPLExaminationModeSpecular);
    _shadowMapView.hidden       = !(_mode & AAPLExaminationModeShadowMap);
    _lightMaskView.hidden       = !(_mode & AAPLExaminationModeMaskedLightVolumes);
    _lightCoverageView.hidden   = !(_mode & AAPLExaminationModeFullLightVolumes);

    [self updateDrawableSize:_renderer.view.drawableSize];
}

- (AAPLExaminationMode)mode
{
    return _mode;
}

- (void)drawAndPresentBuffersWithCommandBuffer:(nonnull id<MTLCommandBuffer>)commandBuffer
{
    NSMutableSet<id<MTLDrawable>> *drawablesToPresent = [NSMutableSet new];

    if(_mode == AAPLExaminationModeAll && _finalFrameView.currentDrawable)
    {
        [drawablesToPresent addObject:_finalFrameView.currentDrawable];
        [self drawFinalRenderWithCommandBuffer:commandBuffer];
        [_finalFrameView draw]; // Resets MTKView currentDrawable for next frame
    }

    if(_mode & AAPLExaminationModeAlbedo && _albedoGBufferView.currentDrawable)
    {
        [drawablesToPresent addObject:_albedoGBufferView.currentDrawable];
        [self drawAlbedoGBufferWithCommandBuffer:commandBuffer];
        [_albedoGBufferView draw]; // Resets MTKView currentDrawable for next frame
    }

    if(_mode & AAPLExaminationModeNormals && _normalsGBufferView.currentDrawable)
    {
        [self drawNormalsGBufferWithCommandBuffer:commandBuffer];
        [drawablesToPresent addObject:_normalsGBufferView.currentDrawable];
        [_normalsGBufferView draw]; // Resets MTKView currentDrawable for next frame
    }

    if(_mode & AAPLExaminationModeDepth && _depthGBufferView.currentDrawable)
    {
        [self drawDepthGBufferWithCommandBuffer:commandBuffer];
        [drawablesToPresent addObject:_depthGBufferView.currentDrawable];
        [_depthGBufferView draw]; // Resets MTKView currentDrawable for next frame
    }

    if(_mode & AAPLExaminationModeShadowGBuffer && _shadowGBufferView.currentDrawable)
    {
        [self drawShadowGBufferWithCommandBuffer:commandBuffer];
        [drawablesToPresent addObject:_shadowGBufferView.currentDrawable];
        [_shadowGBufferView draw]; // Resets MTKView currentDrawable for next frame
    }

    if(_mode & AAPLExaminationModeSpecular && _specularGBufferView.currentDrawable)
    {
        [self drawSpecularGBufferWithCommandBuffer:commandBuffer];
        [drawablesToPresent addObject:_specularGBufferView.currentDrawable];
        [_specularGBufferView draw]; // Resets MTKView currentDrawable for next frame
    }

    if(_mode & AAPLExaminationModeShadowMap && _shadowMapView.currentDrawable)
    {
        [self drawShadowMapWithCommandBuffer:commandBuffer];
        [drawablesToPresent addObject:_shadowMapView.currentDrawable];
        [_shadowMapView draw]; // Resets MTKView currentDrawable for next frame
    }

    if(_mode & AAPLExaminationModeMaskedLightVolumes && _lightMaskView.currentDrawable)
    {
        [self drawLightMaskWithCommandBuffer:commandBuffer];
        [drawablesToPresent addObject:_lightMaskView.currentDrawable];
        [_lightMaskView draw]; // Resets MTKView currentDrawable for next frame
    }

    if(_mode & AAPLExaminationModeFullLightVolumes && _lightCoverageView.currentDrawable)
    {
        [self drawLightVolumesWithCommandBuffer:commandBuffer];
        [drawablesToPresent addObject:_lightCoverageView.currentDrawable];
        [_lightCoverageView draw]; // Resets MTKView currentDrawable for next frame
    }

    [commandBuffer addScheduledHandler:^(id<MTLCommandBuffer> _Nonnull commandBuffer) {
        for(id<MTLDrawable> drawableToPresent in drawablesToPresent)
        {
            [drawableToPresent present];
        }
    }];

}
@end

#endif // END SUPPORT_BUFFER_EXAMINATION
