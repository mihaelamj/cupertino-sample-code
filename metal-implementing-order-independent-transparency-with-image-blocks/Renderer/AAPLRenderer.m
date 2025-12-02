/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The renderer class that sets up Metal and draws each frame.
*/

#import "AAPLRenderer.h"
#import "Shaders/AAPLShaderTypes.h"
#import "AAPLMathUtilities.h"
#import "AAPLActor.h"

static const NSUInteger MaxBuffersInFlight     = 3u;
static const NSUInteger MaxActors              = 32u;
static const NSUInteger ActorCountPerColumn    = 4u;
static const NSUInteger TransparentColumnCount = 4u;

/// Aligns a value to an address.
static size_t Align (size_t value, size_t align)
{
    if (align == 0)
    {
        return value;
    }
    else if ((value & (align-1)) == 0)
    {
        return value;
    }
    else
    {
        return (value+align) & ~(align-1);
    }
}

@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    id<MTLCommandQueue> _commandQueue;

    id<MTLDepthStencilState> _lessEqualDepthStencilState;
    id<MTLDepthStencilState> _noWriteLessEqualDepthStencilState;
    id<MTLDepthStencilState> _noDepthStencilState;

    id<MTLRenderPipelineState> _opaquePipeline;
    id<MTLRenderPipelineState> _initImageBlockPipeline;
    id<MTLRenderPipelineState> _transparencyPipeline;
    id<MTLRenderPipelineState> _blendPipelineState;

    MTLRenderPassDescriptor* _forwardRenderPassDescriptor;

    id<MTLBuffer> _actorParamsBuffers   [MaxBuffersInFlight];
    id<MTLBuffer> _cameraParamsBuffers  [MaxBuffersInFlight];

    id<MTLBuffer> _actorMesh;

    NSMutableArray<AAPLActor*>* _opaqueActors;
    NSMutableArray<AAPLActor*>* _transparentActors;

    MTLSize _optimalTileSize;
    matrix_float4x4 _projectionMatrix;
    float _rotation;
    int8_t _currentBufferIndex;
}

- (nonnull instancetype) initWithMetalKitView:(MTKView *)mtkView
{
    self = [super init];
    if (self)
    {
        _device = mtkView.device;
        _mtkView = mtkView;
        [self loadResources];
        [self loadMetal];
    }
    return self;
}

/// Initializes the app's starting values, and creates actors and constant buffers.
- (void) loadResources
{
    _inFlightSemaphore = dispatch_semaphore_create(MaxBuffersInFlight);
    _currentBufferIndex = 0;
    _enableOrderIndependentTransparency = NO;
    _rotation = 0.0f;
    _enableRotation = true;

    // To use an image block, you must balance the fragment shader's tile dimensions (`tileHeight` and `tileWidth`)
    // with the image block's memory size (`imageblockSampleLength`).
    //
    // A larger `tileWidth` and `tileHeight` may yield better performance because the GPU needs to switch
    // between fewer tiles to render the screen. However, a large tile size means that `imageblockSampleLength` must
    // be smaller.  The number of layers the image block structure supports affects the size
    // of `imageblockSampleLength`. More layers means you must decrease the fragment shader's tile size.
    // This chooses the values to which the renderer sets `tileHeight` and `tileWidth`.
    _optimalTileSize = MTLSizeMake(32lu, 16lu, 1lu);

    vector_float4 genericColors[ActorCountPerColumn];
    genericColors[0] = vector4(0.3f, 0.9f, 0.1f, 1.f);
    genericColors[1] = vector4(0.05f, 0.5f, 0.4f, 1.f);
    genericColors[2] = vector4(0.5f, 0.05f, 0.9f, 1.f);
    genericColors[3] = vector4(0.9f, 0.1f, 0.1f, 1.f);

    _opaqueActors = [NSMutableArray new];
    _transparentActors = [NSMutableArray new];

    vector_float3 startPosition = vector3(7.f, 0.1f, 12.f);
    vector_float3 standardScale = vector3(1.5f, 1.5f, 1.5f);
    vector_float3 standardRotation = vector3(90.f, 0.f, 0.f);

    // Create opaque rotating quad actors at the rear of each column.
    for (NSUInteger i = 0; i < ActorCountPerColumn; ++i)
    {
        AAPLActor* actor = [[AAPLActor alloc] initWithProperties:vector4(0.5f, 0.4f, 0.3f, 1.f)
                                                        position:startPosition rotation:standardRotation scale:standardScale];
        [_opaqueActors addObject:actor];
        startPosition[0] -= 4.5f;
    }

    // Create an opaque floor actor.
    {
        vector_float4 color = vector4(.7f, .7f, .7f, 1.f);
        AAPLActor* actor = [[AAPLActor alloc] initWithProperties:color position:(vector_float3){0.f, -2.f, 6.f} rotation:(vector_float3){0.f, 0.f, 0.f} scale:(vector_float3){8.f, 1.f, 9.f}];
        [_opaqueActors addObject:actor];
    }

    startPosition = vector3(7.f, 0.1f, 0.f);
    vector_float3 curPosition = startPosition;

    // Create the transparent actors.
    for (NSUInteger colIndex = 0; colIndex < TransparentColumnCount; ++colIndex)
    {
        for (NSUInteger rowIndex = 0; rowIndex < ActorCountPerColumn; ++rowIndex)
        {
            genericColors[rowIndex][3] -= 0.2f;
            AAPLActor* actor = [[AAPLActor alloc] initWithProperties:genericColors[rowIndex]
                                                            position:curPosition
                                                            rotation:standardRotation
                                                               scale:standardScale];
            [_transparentActors addObject:actor];
            curPosition[2] += 3.f;
        }
        startPosition[0] -= 4.5f;
        curPosition = startPosition;
    }

    // Create the constant buffers for each frame.
    for (NSUInteger i = 0; i < MaxBuffersInFlight; ++i)
    {
        id<MTLBuffer> actorParamsBuffer = [_device newBufferWithLength: Align(sizeof(ActorParams), BufferOffsetAlign) * MaxActors options:MTLResourceStorageModeShared];
        actorParamsBuffer.label = [NSString stringWithFormat:@"actor params[%lu]", i];
        _actorParamsBuffers[i] = actorParamsBuffer;

        id<MTLBuffer> cameraParamsBuffer = [_device newBufferWithLength:sizeof(CameraParams) options:MTLResourceStorageModeShared];
        cameraParamsBuffer.label = [NSString stringWithFormat:@"camera params[%lu]", i];
        _cameraParamsBuffers[i] = cameraParamsBuffer;
    }
}

/// Creates the Metal render state objects.
- (void) loadMetal
{
    // Check that this GPU supports raster order groups.
    _supportsOrderIndependentTransparency = [_device supportsFamily:MTLGPUFamilyApple4];

    NSError* error;

    NSLog(@"Selected Device: %@", _mtkView.device.name);

    _mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;

    _commandQueue = [_device newCommandQueue];
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    {
        id<MTLFunction> vertexFunc = [defaultLibrary newFunctionWithName:@"forwardVertex"];
        id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"processOpaqueFragment"];

        MTLRenderPipelineDescriptor* renderPipelineDesc = [MTLRenderPipelineDescriptor new];
        renderPipelineDesc.label = @"Unordered alpha blending pipeline";
        renderPipelineDesc.vertexFunction = vertexFunc;
        renderPipelineDesc.fragmentFunction = fragmentFunc;
        renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].pixelFormat = _mtkView.colorPixelFormat;
        renderPipelineDesc.depthAttachmentPixelFormat = _mtkView.depthStencilPixelFormat;
        renderPipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;

        renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].blendingEnabled = true;
        renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].alphaBlendOperation = MTLBlendOperationAdd;
        renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].sourceAlphaBlendFactor = MTLBlendFactorOne;
        renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].destinationAlphaBlendFactor = MTLBlendFactorZero;
        renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
        renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
        renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].rgbBlendOperation = MTLBlendOperationAdd;
        renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].writeMask = MTLColorWriteMaskAll;

        _opaquePipeline = [_device newRenderPipelineStateWithDescriptor:renderPipelineDesc
                                                                  error:&error];
        NSAssert(_opaquePipeline, @"Failed to create opaque render pipeline state: %@", error);
    }

    // Only use transparency effects if the device supports tiles shaders and image blocks.
    if (_supportsOrderIndependentTransparency)
    {
        _enableOrderIndependentTransparency = YES;

        // Set up the transparency pipeline so that it populates the image block with fragment values.
        {
            id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"forwardVertex"];
            id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"processTransparentFragment"];

            MTLRenderPipelineDescriptor* renderPipelineDesc = [MTLRenderPipelineDescriptor new];
            renderPipelineDesc.label = @"Transparent Fragment Store Op";
            renderPipelineDesc.vertexFunction = vertexFunction;
            renderPipelineDesc.fragmentFunction = fragmentFunction;
            renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].blendingEnabled = NO;

            // Disable the color write mask.
            // This fragment shader only writes color data into the image block.
            // It doesn't produce an output for the color attachment.
            renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].writeMask = MTLColorWriteMaskNone;
            renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].pixelFormat = _mtkView.colorPixelFormat;
            renderPipelineDesc.depthAttachmentPixelFormat = _mtkView.depthStencilPixelFormat;
            renderPipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;

            _transparencyPipeline = [_device newRenderPipelineStateWithDescriptor:renderPipelineDesc error:&error];
            NSAssert(_transparencyPipeline, @"Failed to create transparency render pipeline state: %@", error);
        }
        // Configure the kernel tile shader to initialize the image block for each frame.
        {
            id<MTLFunction> kernelTileFunction = [defaultLibrary newFunctionWithName:@"initTransparentFragmentStore"];
            MTLTileRenderPipelineDescriptor *tileDesc = [MTLTileRenderPipelineDescriptor new];
            tileDesc.label = @"Init Image Block Kernel";
            tileDesc.tileFunction = kernelTileFunction;
            tileDesc.colorAttachments[AAPLRenderTargetColor].pixelFormat = _mtkView.colorPixelFormat;
            tileDesc.threadgroupSizeMatchesTileSize = YES;

            _initImageBlockPipeline = [_device newRenderPipelineStateWithTileDescriptor:tileDesc options:0 reflection:nil error:&error];
            NSAssert(_initImageBlockPipeline, @"Failed to create init image block tile shaer pipeline: %@", error);
        }
        // Configure the pipeline to blend transparent and opaque fragments.
        {
            id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"quadPassVertex"];
            id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"blendFragments"];
            MTLRenderPipelineDescriptor* renderPipelineDesc = [MTLRenderPipelineDescriptor new];
            renderPipelineDesc.label = @ "Transparent Fragment Blending";
            renderPipelineDesc.vertexFunction = vertexFunction;
            renderPipelineDesc.fragmentFunction = fragmentFunction;
            renderPipelineDesc.colorAttachments[AAPLRenderTargetColor].pixelFormat = _mtkView.colorPixelFormat;
            renderPipelineDesc.depthAttachmentPixelFormat = _mtkView.depthStencilPixelFormat;
            renderPipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
            renderPipelineDesc.vertexDescriptor = nil;

            _blendPipelineState = [_device newRenderPipelineStateWithDescriptor:renderPipelineDesc error:&error];
            NSAssert(_blendPipelineState, @"Failed to create blend pipeline state: %@", error);
        }
    }
    else
    {
        _enableOrderIndependentTransparency = NO;
    }

    {
        MTLDepthStencilDescriptor* depthStencilDesc = [MTLDepthStencilDescriptor new];
        depthStencilDesc.label = @"DepthCompareAlwaysAndNoWrite";
        depthStencilDesc.depthWriteEnabled = FALSE;
        depthStencilDesc.depthCompareFunction = MTLCompareFunctionAlways;
        depthStencilDesc.backFaceStencil = nil;
        depthStencilDesc.frontFaceStencil = nil;
        _noDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];

        depthStencilDesc.label = @"DepthCompareLessEqualAndWrite";
        depthStencilDesc.depthWriteEnabled = TRUE;
        depthStencilDesc.depthCompareFunction = MTLCompareFunctionLessEqual;
        _lessEqualDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];

        depthStencilDesc.label = @"DepthCompareLessEqualAndNoWrite";
        depthStencilDesc.depthWriteEnabled = FALSE;
        _noWriteLessEqualDepthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];
    }

    _forwardRenderPassDescriptor = [MTLRenderPassDescriptor new];
    _forwardRenderPassDescriptor.colorAttachments[AAPLRenderTargetColor].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    _forwardRenderPassDescriptor.colorAttachments[AAPLRenderTargetColor].loadAction = MTLLoadActionClear;
    _forwardRenderPassDescriptor.colorAttachments[AAPLRenderTargetColor].storeAction = MTLStoreActionStore;
    _forwardRenderPassDescriptor.depthAttachment.clearDepth = 1.0;
    _forwardRenderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
    _forwardRenderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;

    if (_supportsOrderIndependentTransparency)
    {
        // Set the tile size for the fragment shader.
        _forwardRenderPassDescriptor.tileWidth  = _optimalTileSize.width;
        _forwardRenderPassDescriptor.tileHeight = _optimalTileSize.height;

        // Set the image block's memory size.
        _forwardRenderPassDescriptor.imageblockSampleLength = _transparencyPipeline.imageblockSampleLength;
    }

    {
        const Vertex quadVertices[] =
        {
            { {  1,  0, -1 } },
            { { -1,  0, -1 } },
            { { -1,  0,  1 } },

            { {  1,  0, -1 } },
            { { -1,  0,  1 } },
            { {  1,  0,  1 } },
        };

        _actorMesh = [_device newBufferWithBytes:quadVertices
                                          length:sizeof(quadVertices)
                                         options:MTLResourceStorageModeShared];
        _actorMesh.label = @"Quad Mesh";

        NSAssert(_actorMesh, @"Error creating actor vertex buffer: %@", error);
    }
}

/// Delegate callback that responds to changes in the device's orientation or view size changes.
- (void) mtkView:(nonnull MTKView*) view drawableSizeWillChange:(CGSize)size
{
    float aspect = (float)size.width / (float)size.height;
    _projectionMatrix = matrix_perspective_left_hand(radians_from_degrees(65.f), aspect, 1.f, 150.f);
    if (_mtkView.paused)
    {
        [_mtkView draw];
    }
}

/// Updates the application's state for the current frame.
- (void) updateState
{
    _currentBufferIndex = ((_currentBufferIndex + 1) % MaxBuffersInFlight);

    ActorParams* actorParams = (ActorParams*) _actorParamsBuffers[_currentBufferIndex].contents;

    for (NSUInteger i = 0; i < _opaqueActors.count; ++i)
    {
        matrix_float4x4 translationMatrix = matrix4x4_translation(_opaqueActors[i].position);
        matrix_float4x4 scaleMatrix = matrix4x4_scale(_opaqueActors[i].scale);
        matrix_float4x4 rotationXMatrix = matrix4x4_rotation(radians_from_degrees(_opaqueActors[i].rotation.x), 1.f, 0.f, 0.f);
        matrix_float4x4 rotationMatrix = matrix_multiply(matrix4x4_rotation(radians_from_degrees(_rotation), 0.f, 1.f, 0.f), rotationXMatrix);

        // Last opaque actor is tbe floor which has no rotation.
        if (i == _opaqueActors.count - 1)
        {
            rotationMatrix = matrix_identity_float4x4;
        }
        actorParams[i].modelMatrix = matrix_multiply(translationMatrix, matrix_multiply(rotationMatrix, scaleMatrix));
        actorParams[i].color = _opaqueActors[i].color;
    }

    for (NSUInteger i = 0; i < _transparentActors.count; ++i)
    {
        NSUInteger paramsIndex = i + _opaqueActors.count;

        matrix_float4x4 translationMatrix = matrix4x4_translation(_transparentActors[i].position);
        matrix_float4x4 scaleMatrix = matrix4x4_scale(_transparentActors[i].scale);
        matrix_float4x4 rotationXMatrix = matrix4x4_rotation(radians_from_degrees(_transparentActors[i].rotation.x), 1.f, 0.f, 0.f);
        matrix_float4x4 rotationMatrix = matrix_multiply(matrix4x4_rotation(radians_from_degrees(_rotation), 0.f, 1.f, 0.f), rotationXMatrix);

        actorParams[paramsIndex].modelMatrix = matrix_multiply(translationMatrix, matrix_multiply(rotationMatrix, scaleMatrix));
        actorParams[paramsIndex].color = _transparentActors[i].color;
    }

    vector_float3 eyePos = {0.f, 2.f, -12.f};
    vector_float3 eyeTarget = {eyePos.x, eyePos.y - 0.25f, eyePos.z + 1.f};
    vector_float3 eyeUp = {0.f, 1.f, 0.f};
    matrix_float4x4 viewMatrix = matrix_look_at_left_hand(eyePos, eyeTarget, eyeUp);

    CameraParams* cameraParams = (CameraParams*) _cameraParamsBuffers[_currentBufferIndex].contents;
    cameraParams->viewProjectionMatrix = matrix_multiply(_projectionMatrix, viewMatrix);
    cameraParams->cameraPos = eyePos;
    if (_enableRotation)
    {
        _rotation += 1.f;
    }
}

/// Draws all opaque meshes from the opaque actors array.
- (void) drawOpaqueObjects:(id<MTLRenderCommandEncoder>) renderEncoder
            renderPipeline:(id<MTLRenderPipelineState>) renderPipelineState
{
    [renderEncoder pushDebugGroup:@"Opaque Actor Rendering"];

    [renderEncoder setRenderPipelineState:renderPipelineState];
    [renderEncoder setCullMode:MTLCullModeNone];
    [renderEncoder setDepthStencilState:_lessEqualDepthStencilState];

    for (NSUInteger actorIndex = 0; actorIndex < _opaqueActors.count; ++actorIndex)
    {
        size_t offsetValue = actorIndex * Align(sizeof(ActorParams), BufferOffsetAlign);

        [renderEncoder setVertexBufferOffset:offsetValue atIndex:AAPLBufferIndexActorParams];
        [renderEncoder setFragmentBufferOffset:offsetValue atIndex:AAPLBufferIndexActorParams];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];
    }
    [renderEncoder popDebugGroup];
}

/// Draws all the transparent meshes from the transparent actors array.
- (void) drawTransparentObjects:(id<MTLRenderCommandEncoder>) renderEncoder
                 renderPipeline:(id<MTLRenderPipelineState>) renderPipelineState
{
    [renderEncoder pushDebugGroup:@"Transparent Actor Rendering"];

    [renderEncoder setRenderPipelineState:renderPipelineState];
    [renderEncoder setCullMode:MTLCullModeNone];

    // Only test the depth of the transparent geometry against the opaque geometry. This allows
    // transparent fragments behind other transparent fragments to be rasterized and stored in
    // the image block structure.
    [renderEncoder setDepthStencilState:_noWriteLessEqualDepthStencilState];

    for (NSUInteger actorIndex = 0; actorIndex < _transparentActors.count; ++actorIndex)
    {
        size_t offsetValue = (actorIndex + _opaqueActors.count) * Align(sizeof(ActorParams), BufferOffsetAlign);

        [renderEncoder setVertexBufferOffset:offsetValue atIndex:AAPLBufferIndexActorParams];
        [renderEncoder setFragmentBufferOffset:offsetValue atIndex:AAPLBufferIndexActorParams];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];
    }
    [renderEncoder popDebugGroup];
}

/// Binds the constant buffer the app needs to render the 3D actors.
- (void) bindCommonActorBuffers:(id<MTLRenderCommandEncoder>) renderEncoder;
{
    [renderEncoder pushDebugGroup:@"Common Buffer Binding"];

    [renderEncoder setVertexBuffer:_actorMesh offset:0 atIndex:AAPLBufferIndexVertices];

    [renderEncoder setVertexBuffer:_cameraParamsBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexCameraParams];

    [renderEncoder setVertexBuffer:_actorParamsBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexActorParams];

    [renderEncoder setFragmentBuffer:_actorParamsBuffers[_currentBufferIndex] offset:0 atIndex:AAPLBufferIndexActorParams];

    [renderEncoder popDebugGroup];
}

/// Creates a new command buffer after waiting for the last frame to complete.
- (id<MTLCommandBuffer>) beginFrame
{
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Drawable Command Buffer";

    __block dispatch_semaphore_t blockSemaphore = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> commandBuffer)
     {
        dispatch_semaphore_signal(blockSemaphore);
    }];

    [self updateState];
    
    return commandBuffer;
}

/// Draws the opaque and transparent meshes with an explicit image block in a fragment function that implements order-independent transparency.
- (void) drawWithOrderIndependentTransparency:(nonnull MTKView*)view commandBuffer:(id<MTLCommandBuffer>) commandBuffer
{
    id<MTLTexture> drawable = _mtkView.currentDrawable.texture;

    if (!drawable)
    {
        return;
    }

    _forwardRenderPassDescriptor.colorAttachments[AAPLRenderTargetColor].texture = drawable;
    _forwardRenderPassDescriptor.depthAttachment.texture = _mtkView.depthStencilTexture;

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_forwardRenderPassDescriptor];
    renderEncoder.label = @"Forward Pass";

    // Initialize the image block's memory before rendering.
    [renderEncoder pushDebugGroup:@"Init Image Block"];
    [renderEncoder setRenderPipelineState:_initImageBlockPipeline];
    [renderEncoder dispatchThreadsPerTile:_optimalTileSize];
    [renderEncoder popDebugGroup];

    [self bindCommonActorBuffers:renderEncoder];
    [self drawOpaqueObjects:renderEncoder renderPipeline:_opaquePipeline];
    [self drawTransparentObjects:renderEncoder renderPipeline:_transparencyPipeline];

    [renderEncoder pushDebugGroup:@"Blend Fragments"];
    [renderEncoder setRenderPipelineState:_blendPipelineState];
    [renderEncoder setCullMode:MTLCullModeNone];
    [renderEncoder setDepthStencilState:_noDepthStencilState];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [renderEncoder popDebugGroup];

    [renderEncoder endEncoding];
}

/// Draws the opaque and transparent meshes with a pipeline's alpha blending.
- (void) drawUnorderedAlphaBlending:(nonnull MTKView*) view
                      commandBuffer:(id<MTLCommandBuffer>) commandBuffer
{
    id<MTLTexture> drawable = _mtkView.currentDrawable.texture;

    if (!drawable)
    {
        return;
    }

    _forwardRenderPassDescriptor.colorAttachments[AAPLRenderTargetColor].texture = drawable;
    _forwardRenderPassDescriptor.depthAttachment.texture = _mtkView.depthStencilTexture;

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_forwardRenderPassDescriptor];
    renderEncoder.label = @"Forward Render Pass";

    [self bindCommonActorBuffers:renderEncoder];
    [self drawOpaqueObjects:renderEncoder renderPipeline:_opaquePipeline];
    [self drawTransparentObjects:renderEncoder renderPipeline:_opaquePipeline];

    [renderEncoder endEncoding];
}

/// Renders a single frame to a MetalKit view.
- (void) drawInMTKView:(nonnull MTKView*) view
{
    id<MTLCommandBuffer> commandBuffer = [self beginFrame];
    if (_enableOrderIndependentTransparency)
    {
        [self drawWithOrderIndependentTransparency:view commandBuffer:commandBuffer];
    }
    else
    {
        [self drawUnorderedAlphaBlending:view commandBuffer:commandBuffer];
    }

    [commandBuffer presentDrawable:_mtkView.currentDrawable];
    [commandBuffer commit];
}
@end
