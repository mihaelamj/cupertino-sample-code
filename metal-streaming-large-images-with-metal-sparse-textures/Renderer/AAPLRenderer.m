/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the renderer class that performs Metal set up and per-frame rendering.
*/
#import "AAPLRenderer.h"
#import "AAPLConfig.h"
#import "Shaders/AAPLShaderTypes.h"
#import "AAPLMathUtilities.h"
#import "AAPLSparseTexture.h"
#import "AAPLStreamedTextureDataBacking.h"

@implementation AAPLRenderer
{
    id<MTLDevice>           _device;
    MTKView*                _mtkView;
    dispatch_semaphore_t    _inFlightSemaphore;
    id<MTLCommandQueue>     _commandQueue;
    NSUInteger              _currentBufferIndex;
    
    id<MTLRenderPipelineState> _forwardRenderPipelineState;
    MTLRenderPassDescriptor*   _forwardRenderPassDescriptor;

    id<MTLBuffer> _sampleParamsBuffer[AAPLMaxFramesInFlight];
    
    id<MTLBuffer> _quadVerticesBuffer;
    
    matrix_float4x4 _projectionMatrix;
    
    AAPLSparseTexture* _sparseTexture;
    float _offsetZ;
    float _meshesZ;

#if ASYNCHRONOUS_TEXTURE_UPDATES
    dispatch_queue_t _dispatch_queue;
#endif

#if DEBUG_SPARSE_TEXTURE
    id<MTLRenderPipelineState> _debugSparseTextureQuadRenderPipelineState;
    MTLRenderPassDescriptor*   _debugSparseTextureQuadRenderPassDescriptor;
#endif
}

/// Create MTKView and load resources.
- (nonnull instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    if (self = [super init])
    {
        _device = mtkView.device;
        _mtkView = mtkView;
        [self loadResources];
        [self loadMetal];
        
#if ASYNCHRONOUS_TEXTURE_UPDATES
        _dispatch_queue = dispatch_queue_create("com.example.apple-samplecode.sparse-texturing-queue", DISPATCH_QUEUE_SERIAL);
#endif
    }
    return self;
}

/// Initialize the starting values and create the constants and geometry buffers.
- (void)loadResources
{
    _inFlightSemaphore    = dispatch_semaphore_create(AAPLMaxFramesInFlight);
    _currentBufferIndex   = 0;
    _offsetZ              = 1.2f;
    _meshesZ              = 60.f;
    _animationEnabled       = NO;
    
    for (NSUInteger i = 0; i < AAPLMaxFramesInFlight; ++i)
    {
        id<MTLBuffer> sampleParamsBuffer = [_device newBufferWithLength:sizeof(SampleParams) options:MTLResourceStorageModeShared];
        sampleParamsBuffer.label = [NSString stringWithFormat:@"sample frame params[%lu]", i];
        _sampleParamsBuffer[i] = sampleParamsBuffer;
    }
    
    static const QuadVertex quadVertices[] =
    {
        { .position = (vector_float4){ -1.0f, -1.0f, 0.f, 1.f }, .texCoord = (vector_float2){0.f, 0.f} },
        { .position = (vector_float4){ -1.0f,  1.0f, 0.f, 1.f }, .texCoord = (vector_float2){0.f, 1.f} },
        { .position = (vector_float4){  1.0f, -1.0f, 0.f, 1.f }, .texCoord = (vector_float2){1.f, 0.f} },
        { .position = (vector_float4){  1.0f, -1.0f, 0.f, 1.f }, .texCoord = (vector_float2){1.f, 0.f} },
        { .position = (vector_float4){ -1.0f,  1.0f, 0.f, 1.f }, .texCoord = (vector_float2){0.f, 1.f} },
        { .position = (vector_float4){  1.0f,  1.0f, 0.f, 1.f }, .texCoord = (vector_float2){1.f, 1.f} }
    };
    _quadVerticesBuffer = [_device newBufferWithBytes:quadVertices length:sizeof(quadVertices) options:MTLResourceStorageModeShared];
}

/// Create the Metal render state objects.
- (void)loadMetal
{
    NSError* error = nil;
    NSLog(@"Selected Device: %@", _device.name);
    _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    _commandQueue = [_device newCommandQueue];
    
    #if USE_SMALL_SPARSE_TEXTURE_HEAP
    const NSUInteger heapSize = 2 * 1048576;
    #else
    const NSUInteger heapSize = 16 * 1048576;
    #endif
    
    NSURL* _sparseTexturePath = [[NSBundle mainBundle] URLForResource:@"apple_park.ktx" withExtension:nil];
    _sparseTexture = [[AAPLSparseTexture alloc] initWithDevice:_device
                                                          path:_sparseTexturePath
                                                  commandQueue:_commandQueue
                                                      heapSize:heapSize];
    
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    // Create the forward plane with sparse texture rendering pipeline.
    {
        id<MTLFunction> vertexFunc   = [defaultLibrary newFunctionWithName:@"forwardPlaneVertex"];
        id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"forwardWithSparseTextureFragment"];
        
        MTLRenderPipelineDescriptor* renderPipelineDesc = [MTLRenderPipelineDescriptor new];
        renderPipelineDesc.vertexFunction = vertexFunc;
        renderPipelineDesc.fragmentFunction = fragmentFunc;
        renderPipelineDesc.vertexDescriptor = nil;
        renderPipelineDesc.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
        renderPipelineDesc.depthAttachmentPixelFormat = _mtkView.depthStencilPixelFormat;
        renderPipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
        
        _forwardRenderPipelineState = [_device
                                           newRenderPipelineStateWithDescriptor:renderPipelineDesc
                                           error:&error];
        NSAssert(_forwardRenderPipelineState, @"Failed to create the forward plane with sparse texture render pipeline state.");
    }
    
    // Prefill the render pass descriptors with its clear, load, and store actions.
    {
        _forwardRenderPassDescriptor = [MTLRenderPassDescriptor new];
        _forwardRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.1, 1.0);
        _forwardRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _forwardRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _forwardRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
        _forwardRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        _forwardRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    }

#if DEBUG_SPARSE_TEXTURE
    // Create debug sparse texture quad pipeline.
    {
        id<MTLFunction> vertexFunc   = [defaultLibrary newFunctionWithName:@"debugSparseTextureQuadVertex"];
        id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"debugSparseTextureQuadFragment"];

        MTLRenderPipelineDescriptor* renderPipelineDesc = [MTLRenderPipelineDescriptor new];
        renderPipelineDesc.vertexFunction = vertexFunc;
        renderPipelineDesc.fragmentFunction = fragmentFunc;
        renderPipelineDesc.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
        renderPipelineDesc.depthAttachmentPixelFormat = MTLPixelFormatInvalid;
        renderPipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;

        _debugSparseTextureQuadRenderPipelineState = [_device
                                           newRenderPipelineStateWithDescriptor:renderPipelineDesc
                                           error:&error];
        NSAssert(_debugSparseTextureQuadRenderPipelineState, @"Failed to create the debug sparse texture quad render pipeline state.");
    }
    
    // Prefill render pass descriptors for clear, load, and store actions.
    {
        _debugSparseTextureQuadRenderPassDescriptor = [MTLRenderPassDescriptor new];
        _debugSparseTextureQuadRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0);
        _debugSparseTextureQuadRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
        _debugSparseTextureQuadRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _debugSparseTextureQuadRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
        _debugSparseTextureQuadRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionDontCare;
        _debugSparseTextureQuadRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    }
#endif

}

/// MTKViewDelegate Callback: Respond to device orientation change or other view size change.
- (void)mtkView:(nonnull MTKView*)view drawableSizeWillChange:(CGSize)size
{
    float aspect = (float)size.width / (float)size.height;
    _projectionMatrix = matrix_perspective_left_hand(radians_from_degrees(75.f), aspect, 1.f, 1000.f);
}

/// Update the application state and SampleParamsBuffer for shaders.
- (void)updateAnimationAndBuffers
{
    if (_animationEnabled)
    {
        _meshesZ += _offsetZ;
    }
    
    if (_meshesZ >= 340.f)
    {
        _offsetZ *= -1.f;
        _meshesZ = 339.f;
    }
    
    if (_meshesZ <= -180.f)
    {
        _offsetZ *= -1.f;
        _meshesZ = -179.f;
    }
    
    SampleParams *sample = _sampleParamsBuffer[_currentBufferIndex].contents;

    matrix_float4x4 scaleMatrix = matrix4x4_scale((vector_float3){300.0, 300.0, 80.0});
    matrix_float4x4 rotationMatrix = matrix4x4_rotation(radians_from_degrees(90.f), 1.f, 0.f, 0.f);
    matrix_float4x4 translationMatrix = matrix4x4_translation((vector_float3){0.f, -4.f, _meshesZ});
    sample->modelMatrix = matrix_multiply(translationMatrix, matrix_multiply(rotationMatrix, scaleMatrix));
    sample->normalMatrix = matrix3x3_upper_left(sample->modelMatrix);

    vector_float3 eyePos = {0.f, 25.f, -8.f};
    vector_float3 eyeTarget = {eyePos.x, eyePos.y - 0.5f, eyePos.z + 1.f};
    
    vector_float3 eyeUp = {0.f, 1.f, 0.f};
    matrix_float4x4 viewMatrix = matrix_look_at_left_hand(eyePos, eyeTarget, eyeUp);
    
    sample->viewProjectionMatrix = matrix_multiply(_projectionMatrix, viewMatrix);

    sample->quadParamsOffsetAndScale = (vector_float4){-0.65f, -0.65f, 0.f, 0.35f};

    sample->sparseTextureSizeInTiles = (vector_float2){
        (float)_sparseTexture.sizeInTiles.width,
        (float)_sparseTexture.sizeInTiles.height };
}

/// Render Plane using sparse texture.
- (void)drawPlaneWithSparseTexture:(id<MTLRenderCommandEncoder>)renderEncoder
{
    [renderEncoder setCullMode:MTLCullModeNone];
    [renderEncoder setRenderPipelineState:_forwardRenderPipelineState];
    [renderEncoder setVertexBuffer:_sampleParamsBuffer[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexSampleParams];
    [renderEncoder setFragmentBuffer:_sampleParamsBuffer[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexSampleParams];
    [renderEncoder setFragmentBuffer:_sparseTexture.residencyBuffer offset:0 atIndex:AAPLBufferIndexResidency];
    [renderEncoder setVertexBuffer:_quadVerticesBuffer offset:0 atIndex:0];
    [renderEncoder setFragmentTexture:_sparseTexture.sparseTexture atIndex:AAPLTextureIndexBaseColor];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

/// Render the graphics scene.
- (void)drawScene:(id<MTLCommandBuffer>)commandBuffer
{
    _forwardRenderPassDescriptor.colorAttachments[0].texture = _mtkView.currentDrawable.texture;
    _forwardRenderPassDescriptor.depthAttachment.texture = _mtkView.depthStencilTexture;
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_forwardRenderPassDescriptor];
    
    [renderEncoder pushDebugGroup:@"Draw scene"];
    
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setVertexBuffer:_sampleParamsBuffer[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexSampleParams];
    [renderEncoder setFragmentBuffer:_sampleParamsBuffer[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexSampleParams];

    [self drawPlaneWithSparseTexture:renderEncoder];
    
    [renderEncoder popDebugGroup];
    [renderEncoder endEncoding];
}

#if DEBUG_SPARSE_TEXTURE
/// Render the NDC quad that displays the streamed tile region mipmap level 0 of the sparse texture.
- (void)drawDebugSparseTextureTiles:(id<MTLCommandBuffer>)commandBuffer
{
    _debugSparseTextureQuadRenderPassDescriptor.colorAttachments[0].texture = _mtkView.currentDrawable.texture;
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_debugSparseTextureQuadRenderPassDescriptor];
    
    [renderEncoder pushDebugGroup:@"Draw debug visualization"];
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setRenderPipelineState:_debugSparseTextureQuadRenderPipelineState];
    [renderEncoder setVertexBuffer:_quadVerticesBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_sampleParamsBuffer[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexSampleParams];
    [renderEncoder setFragmentBuffer:_sampleParamsBuffer[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexSampleParams];

    [renderEncoder setFragmentBuffer:_sparseTexture.residencyBuffer offset:0 atIndex:AAPLBufferIndexResidency];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    
    [renderEncoder popDebugGroup];
    [renderEncoder endEncoding];
}
#endif

/// Draw call starts here.
- (void)drawInMTKView:(nonnull MTKView*)view
{
    // Wait for a free command queue and update the current uniform buffer index.
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    _currentBufferIndex = ((_currentBufferIndex + 1) % AAPLMaxFramesInFlight);
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Main render cmd buffer";
    
    // Update the animation and uniform buffers for the sample.
    [self updateAnimationAndBuffers];

    // Begin the forward render pass.
    [self drawScene:commandBuffer];
    
    #if DEBUG_SPARSE_TEXTURE
    // Draw a visualization of the sparse texture residency buffer.
    [self drawDebugSparseTextureTiles:commandBuffer];
    #endif
    
    // Register the completion handler for the command buffer.
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuffer)
    {
        dispatch_semaphore_signal(self->_inFlightSemaphore);
    }];
    [commandBuffer presentDrawable:_mtkView.currentDrawable];
    [commandBuffer commit];
    
    #if ASYNCHRONOUS_TEXTURE_UPDATES
    dispatch_async(_dispatch_queue, ^{
        // Process the sparse texture access counters, and map and blit tiles.
        [self->_sparseTexture update:self->_currentBufferIndex];
    });
    #else
    // Process the sparse texture access counters, and map and blit tiles.
    [_sparseTexture update:_currentBufferIndex];
    #endif

    // Update the info string for the user interface.
    _infoString = _sparseTexture.infoString;
}

@end
