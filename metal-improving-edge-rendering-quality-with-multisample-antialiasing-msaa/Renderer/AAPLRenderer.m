/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the renderer class that renders a set of thin shards with multisample antialiasing (MSAA).
*/

#import "AAPLRenderer.h"
#import "AAPLShaderTypes.h"
#import "AAPLConfig.h"

/// A constant that specifies the number of thin shards to draw.
static const int AAPLNumberOfShards = 7;

/// Creates a rotation matrix with the specified angle in radians.
static inline matrix_float2x2 make_2d_rotation_matrix(float angle)
{
    return simd_matrix_from_rows(simd_make_float2(cos(angle), -sin(angle)),
                                 simd_make_float2(sin(angle),  cos(angle)));
}

#pragma mark - Renderer Implementation

/// A class responsible for updating and rendering the view.
@implementation AAPLRenderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    
    id<MTLBuffer> _shardsScene;
    MTLPixelFormat _renderTargetPixelFormat;
    MTLPixelFormat _drawablePixelFormat;
    MTLTextureDescriptor* _multisampleTextureDescriptor;
    id<MTLTexture> _multisampleTexture;
    MTLRenderPipelineDescriptor* _renderPipelineDescriptor;
    id<MTLRenderPipelineState> _renderPipelineState;
    id<MTLFunction> _fragmentFunctionNonHDR;
    id<MTLFunction> _fragmentFunctionHDR;
    BOOL _usesHDR;
    
    MTLTextureDescriptor* _resolveTextureDescriptor;
    id<MTLTexture> _resolveResultTexture;
    id<MTLRenderPipelineState> _compositionPipelineState;
    
    // A custom MSAA resolve in immediate-mode rendering (IMR) mode with a compute pass.
    id<MTLFunction> _averageResolveIMRKernelFunction;
    id<MTLFunction> _hdrResolveIMRKernelFunction;
    id<MTLComputePipelineState> _resolveComputePipelineState;
    MTLSize _intrinsicThreadgroupSize;
    MTLSize _threadgroupsInGrid;
    
    // A custom MSAA resolve during a tile stage in a render pass on Apple GPUs.
    id<MTLFunction> _averageResolveTileKernelFunction;
    id<MTLFunction> _hdrResolveTileKernelFunction;
    MTLTileRenderPipelineDescriptor* _resolveTileRenderPipelineDescriptor;
    id<MTLRenderPipelineState> _resolveTileRenderPipelineState;
    
    vector_uint2 _viewportSize;
    NSUInteger _frameNum;
    float _backgroundBrightness;
}

/// Checks whether the device supports tile shaders that were introduced with Apple GPU family 4.
- (BOOL)supportsTileShaders
{
    return [_device supportsFamily:MTLGPUFamilyApple4];
}

#pragma mark - Initialization

- (nonnull instancetype)initWithMetalDevice:(nonnull id<MTLDevice>)device
                        drawablePixelFormat:(MTLPixelFormat)drawablePixelFormat
{
    if (self = [super init])
    {
        _animated = YES;
        
        _frameNum = 0;
        
        _backgroundBrightness = 0.05;
        
        _renderingQuality = 1.0;
        
        _device = device;
        
        _commandQueue = [_device newCommandQueue];

        // The app uses the `RGBA16Float` format to hold HDR values in the subpixel samples until they're resolved.
        // Keep in mind that the `RGBA16Float` format uses twice the memory as an 8-bit format.
        _renderTargetPixelFormat = MTLPixelFormatRGBA16Float;

        // The drawable pixel format is either an 8-bit or 16-bit pixel format.
        _drawablePixelFormat = drawablePixelFormat;
        
        _resolvingOnTileShaders = NO;
        
        _antialiasingEnabled = YES;
        
        _antialiasingOptionsChanged = NO;
        
        // Set the default sample count to the maximum that is supported on all devices.
        _antialiasingSampleCount = 4;
        
        _resolveOption = AAPLResolveOptionBuiltin;
        
        id<MTLLibrary> shaderLib = [_device newDefaultLibrary];
        
        NSAssert(shaderLib, @"Couldn't create the default shader library.");
        
        [self createRenderPipelineState:shaderLib];
        
        [self createResolveKernelPrograms:shaderLib];
        
        [self createResolvePipelineState:shaderLib];
        
        [self createSceneVertices];
        
        [self createMultisampleTextureDescriptor];
    }
    return self;
}

- (void)createRenderPipelineState:(id<MTLLibrary>)metalLibrary
{
    id<MTLFunction> vertexFunction = [metalLibrary newFunctionWithName:@"vertexShader"];
    NSAssert(vertexFunction, @"Couldn't load vertex function from default library.");
    
    _fragmentFunctionNonHDR = [metalLibrary newFunctionWithName:@"fragmentShader"];
    NSAssert(_fragmentFunctionNonHDR, @"Couldn't load fragment function from default library.");
    
    _fragmentFunctionHDR = [metalLibrary newFunctionWithName:@"fragmentShaderHDR"];
    NSAssert(_fragmentFunctionHDR, @"Couldn't load fragment function from default library.");

    _renderPipelineDescriptor = [MTLRenderPipelineDescriptor new];
    
    _renderPipelineDescriptor.label                           = @"RenderPipeline";
    _renderPipelineDescriptor.vertexFunction                  = vertexFunction;
    _renderPipelineDescriptor.fragmentFunction                = _fragmentFunctionNonHDR;
    _renderPipelineDescriptor.colorAttachments[0].pixelFormat = _renderTargetPixelFormat;
    if (@available(macOS 13.0, iOS 16.0, *)) {
        _renderPipelineDescriptor.rasterSampleCount = _antialiasingSampleCount;
    } else {
        _renderPipelineDescriptor.sampleCount = _antialiasingSampleCount;
    }
    
    NSError *error;
    
    _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:_renderPipelineDescriptor
                                                                   error:&error];
    NSAssert(_renderPipelineState, @"Failed to create the pipeline state: %@", error);
}

- (void)createResolveKernelPrograms:(id<MTLLibrary>)metalLibrary
{
    if (self.supportsTileShaders)
    {
        _averageResolveTileKernelFunction = [metalLibrary newFunctionWithName:@"averageResolveTileKernel"];
        NSAssert(_averageResolveTileKernelFunction, @"Couldn't load average resolve function from default library.");
        
        _hdrResolveTileKernelFunction = [metalLibrary newFunctionWithName:@"hdrResolveTileKernel"];
        NSAssert(_hdrResolveTileKernelFunction, @"Couldn't load HDR resolve function from default library.");
    }
    
    // Create IMR kernels as a fallback.
    {
        _averageResolveIMRKernelFunction = [metalLibrary newFunctionWithName:@"averageResolveKernel"];
        NSAssert(_averageResolveIMRKernelFunction, @"Couldn't load average resolve function from default library.");
        
        _hdrResolveIMRKernelFunction = [metalLibrary newFunctionWithName:@"hdrResolveKernel"];
        NSAssert(_hdrResolveIMRKernelFunction, @"Couldn't load HDR resolve function from default library");
    }
}

- (void)createResolvePipelineState:(id<MTLLibrary>)metalLibrary
{
    NSError *error;
    
    if (self.supportsTileShaders)
    {
        _resolveTileRenderPipelineDescriptor = [MTLTileRenderPipelineDescriptor new];
        
        _resolveTileRenderPipelineDescriptor.label = @"CustomResolvePipeline";
        _resolveTileRenderPipelineDescriptor.tileFunction = _averageResolveTileKernelFunction;
        _resolveTileRenderPipelineDescriptor.threadgroupSizeMatchesTileSize = YES;
        _resolveTileRenderPipelineDescriptor.colorAttachments[0].pixelFormat = _renderTargetPixelFormat;
        
        _resolveTileRenderPipelineDescriptor.rasterSampleCount = _antialiasingSampleCount;
        
        _resolveTileRenderPipelineState = [_device newRenderPipelineStateWithTileDescriptor:_resolveTileRenderPipelineDescriptor
                                                                                    options:0
                                                                                 reflection:nil
                                                                                      error:&error];
        NSAssert(_resolveTileRenderPipelineState, @"Failed aquiring pipeline state: %@", error);
    }
    
    // The tile-based resolve is exclusive to Apple Silicon devices, so use a compute pass if the device only supports a custom MSAA resolve.
    {
        // Create compute pipeline for traditional resolve.
        {
            _resolveComputePipelineState = [_device newComputePipelineStateWithFunction:_averageResolveIMRKernelFunction
                                                                                  error:nil];
            
            NSUInteger threadgroupHeight = _resolveComputePipelineState.maxTotalThreadsPerThreadgroup / _resolveComputePipelineState.threadExecutionWidth;
            
            _intrinsicThreadgroupSize = MTLSizeMake(_resolveComputePipelineState.threadExecutionWidth, threadgroupHeight, 1);
        }
    }
    
    // Composite (copy) the rendered scene to the render target.
    {
        id<MTLFunction> compositionVertexProgram = [metalLibrary newFunctionWithName:@"compositeVertexShader"];
        NSAssert(compositionVertexProgram, @"Couldn't load copy vertex function from default library");
        
        id<MTLFunction> compositionFragmentProgram = [metalLibrary newFunctionWithName:@"compositeFragmentShader"];
        NSAssert(compositionFragmentProgram, @"Couldn't load copy fragment function from default library");
        
        MTLRenderPipelineDescriptor * compositionPipelineDescriptor = [MTLRenderPipelineDescriptor new];
        
        compositionPipelineDescriptor.label                            = @"CompositionResolveResultPipeline";
        compositionPipelineDescriptor.vertexFunction                   = compositionVertexProgram;
        compositionPipelineDescriptor.fragmentFunction                 = compositionFragmentProgram;
        compositionPipelineDescriptor.colorAttachments[0].pixelFormat  = _drawablePixelFormat;
        
        _compositionPipelineState = [_device newRenderPipelineStateWithDescriptor:compositionPipelineDescriptor
                                                                            error:&error];
        NSAssert(_compositionPipelineState, @"Failed acquiring pipeline state: %@", error);
    }
}

- (void)createSceneVertices
{
    static const vector_float3 AAPLSwatches[AAPLNumberOfShards] =
    {
        {             1.f,           1.f,           1.f },
        {   120.f / 255.f, 190.f / 255.f,  33.f / 255.f },
        {   255.f / 255.f, 199.f / 255.f,  44.f / 255.f },
        {   255.f / 255.f, 103.f / 255.f,  32.f / 255.f },
        {   200.f / 255.f,  16.f / 255.f,  46.f / 255.f },
        {   173.f / 255.f,  26.f / 255.f, 172.f / 255.f },
        {     0.f / 255.f, 163.f / 255.f, 224.f / 255.f },
    };
    
    AAPLVertex sceneVertices[AAPLNumberOfShards * (3 + 3)];
    
    // Create the inner shards with normal intensity colors.
    
    for (int index = 0; index < AAPLNumberOfShards; index ++)
    {
        
        const vector_float3 swatches[3] =
        {
            AAPLSwatches[index],
            AAPLSwatches[index],
            AAPLSwatches[index],
        };
        
        float placementAngle = (float)index / (float)AAPLNumberOfShards * 2 * M_PI;
        
        [self createShardInPlace:&sceneVertices[index * 3]
                        swatches:swatches
               directionReversed:NO
                angularPlacement:placementAngle
                          offset:vector2(10.f, 0.f)];
    }
    
    // Use brighter colors on the outer shards for the HDR resolve.
    
    const int outerArrangementOffset = AAPLNumberOfShards * 3;
    for (int index = 0; index < AAPLNumberOfShards; index ++)
    {
        
        const vector_float3 swatches[3] =
        {
            AAPLSwatches[index],
            AAPLSwatches[index] * 10,
            AAPLSwatches[index] * 10,
        };
        
        float placementAngle = ((float)index + 0.5) / (float)AAPLNumberOfShards * 2 * M_PI;
        
        [self createShardInPlace:&sceneVertices[index * 3 + outerArrangementOffset]
                        swatches:swatches
               directionReversed:YES
                angularPlacement:placementAngle
                          offset:vector2(30.f, 0.f)];
    }
    
    // Create a vertex buffer and initialize it with the vertex data.
    _shardsScene = [_device newBufferWithBytes:sceneVertices
                                        length:sizeof(sceneVertices)
                                       options:MTLResourceStorageModeShared];
    
    _shardsScene.label = @"Shards Scene";
}

- (void)createShardInPlace:(AAPLVertex*)vertices
                  swatches:(const vector_float3[3])swatches
         directionReversed:(bool)reversed
          angularPlacement:(float)radianAngle
                    offset:(vector_float2)offset

{
    matrix_float2x2 rotationMatrix = make_2d_rotation_matrix(radianAngle);
    
    static const vector_float2 triangleVertices[] =
    {
        {   0.f,    0.f},
        { 100.f,    3.f},
        { 100.f,   -3.f},
    };
    
    vector_short2 direction = {reversed ? -1 : 1, 1};
    
    // Create a triangle shard with its three vertices.
    for (int index = 0; index < 3; index ++)
    {
        vertices[index].position    = simd_mul(rotationMatrix, triangleVertices[index] + offset);
        vertices[index].color       = swatches[index];
        vertices[index].direction   = direction;
    }
}

- (void)createMultisampleTextureDescriptor
{
    _multisampleTextureDescriptor = [MTLTextureDescriptor new];
    
    _multisampleTextureDescriptor.pixelFormat = _renderTargetPixelFormat;
    
    _multisampleTextureDescriptor.textureType = MTLTextureType2DMultisample;
    _multisampleTextureDescriptor.sampleCount = _antialiasingSampleCount;
    
    if (_resolvingOnTileShaders)
    {
        _multisampleTextureDescriptor.usage = MTLTextureUsageRenderTarget;
        _multisampleTextureDescriptor.storageMode = MTLStorageModeMemoryless;
    }
    else
    {
        _multisampleTextureDescriptor.usage = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
        _multisampleTextureDescriptor.storageMode = MTLStorageModePrivate;
    }
    
    _resolveTextureDescriptor = [MTLTextureDescriptor new];
    _resolveTextureDescriptor.pixelFormat = _renderTargetPixelFormat;
    _resolveTextureDescriptor.storageMode = MTLStorageModePrivate;
    _resolveTextureDescriptor.usage = MTLResourceUsageRead | MTLTextureUsageRenderTarget;
    _resolveTextureDescriptor.usage |= (!_resolvingOnTileShaders && _resolveOption != AAPLResolveOptionBuiltin) ? MTLResourceUsageWrite : 0;
    _resolveTextureDescriptor.textureType = MTLTextureType2D;
}

- (void)createMultisampleTexture
{
    _multisampleTextureDescriptor.width = _viewportSize.x;
    _multisampleTextureDescriptor.height = _viewportSize.y;
    
    _multisampleTexture = [_device newTextureWithDescriptor:_multisampleTextureDescriptor];
    
    _multisampleTexture.label = @"Multisampled Texture";
    
    _resolveTextureDescriptor.width = _viewportSize.x;
    _resolveTextureDescriptor.height = _viewportSize.y;
    
    _resolveResultTexture = [_device newTextureWithDescriptor:_resolveTextureDescriptor];
    
    _resolveResultTexture.label = @"Resolved Texture";
}

#pragma mark - Render Loop

- (void)drawInMTKView:(nonnull MTKView*)view
{
    if (_antialiasingOptionsChanged)
    {
        [self updateAntialiasingInPipeline];
        
        _antialiasingOptionsChanged = NO;
    }
    
    // Create a new command buffer for each render pass to the current drawable.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    id<CAMetalDrawable> currentDrawable = [view currentDrawable];
    
    // Skip rendering the frame if the current drawable is nil.
    if (!currentDrawable)
    {
        return;
    }
    
    MTLRenderPassDescriptor *renderPassDescriptor = [MTLRenderPassDescriptor new];
    
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(_backgroundBrightness, _backgroundBrightness, _backgroundBrightness, 1);
    
    BOOL shouldResolve = _antialiasingEnabled && (_resolvingOnTileShaders || (_resolveOption == AAPLResolveOptionBuiltin));
    if (_antialiasingEnabled)
    {
        if (_resolvingOnTileShaders)
        {
            renderPassDescriptor.tileWidth = AAPLTileWidth;
            renderPassDescriptor.tileHeight = AAPLTileHeight;
            renderPassDescriptor.imageblockSampleLength = 32;
        }
        
        MTLStoreAction storeAction = shouldResolve ? MTLStoreActionMultisampleResolve : MTLStoreActionStore;
        renderPassDescriptor.colorAttachments[0].storeAction = storeAction;
        renderPassDescriptor.colorAttachments[0].texture = _multisampleTexture;
        renderPassDescriptor.colorAttachments[0].resolveTexture = shouldResolve ? _resolveResultTexture : nil;
    }
    else
    {
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDescriptor.colorAttachments[0].texture = _resolveResultTexture;
        renderPassDescriptor.colorAttachments[0].resolveTexture = nil;
    }
    
    id<MTLRenderCommandEncoder> renderEncoder =
    [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    
    renderEncoder.label = [NSString stringWithFormat:@"%@%@", @"Render", shouldResolve ? @" + Resolve" : @""];
    
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    
    [renderEncoder setVertexBuffer:_shardsScene
                            offset:0
                           atIndex:AAPLVertexInputIndexVertices ];
    
    {
        AAPLUniforms uniforms;
        
        if (_animated)
        {
            _frameNum++;
        }
        uniforms.rotationMatrix = make_2d_rotation_matrix((float)_frameNum * 0.001 + 0.1);
        
        uniforms.viewportSize = _viewportSize;
        
        [renderEncoder setVertexBytes:&uniforms
                               length:sizeof(uniforms)
                              atIndex:AAPLVertexInputIndexUniforms ];
    }
    
    // Render both the inner and outer layers of shards.
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:AAPLNumberOfShards * 2 * 3];
    
    // Apply the custom resolve with either a tile-based or an IMR pipeline.
    if (_resolvingOnTileShaders)
    {
        if (_antialiasingEnabled && _resolveOption != AAPLResolveOptionBuiltin)
        {
            // Resolve MSAA with a custom resolve filter.
            [renderEncoder setRenderPipelineState:_resolveTileRenderPipelineState];
            
            [renderEncoder dispatchThreadsPerTile:MTLSizeMake(16, 16, 1)];
        }
        
        [renderEncoder endEncoding];
    }
    else
    {
        [renderEncoder endEncoding];
        
        if (_antialiasingEnabled && _resolveOption != AAPLResolveOptionBuiltin)
        {
            // Resolve the multisample texture with the chosen custom filter.
            id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
            
            computeEncoder.label = @"Resolve on Compute";
            
            [computeEncoder setComputePipelineState:_resolveComputePipelineState];
            
            [computeEncoder setTexture:_multisampleTexture atIndex:0];
            [computeEncoder setTexture:_resolveResultTexture atIndex:1];
            
            [computeEncoder dispatchThreadgroups:_threadgroupsInGrid
                           threadsPerThreadgroup:_intrinsicThreadgroupSize];
            
            [computeEncoder endEncoding];
        }
    }
    
    // Composite (copy) the resolved texture to the render target.
    {
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        renderPassDescriptor.colorAttachments[0].texture = currentDrawable.texture;
        renderPassDescriptor.colorAttachments[0].resolveTexture = nil;
        
        renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        renderEncoder.label = @"Composite Pass";
        
        [renderEncoder setRenderPipelineState:_compositionPipelineState];
        
        [renderEncoder setFragmentTexture:_resolveResultTexture atIndex:0];
        
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
        
        [renderEncoder endEncoding];
    }
    
    [commandBuffer presentDrawable:currentDrawable];
    
    [commandBuffer commit];
}

- (void)drawableSizeWillChange:(CGSize)drawableSize
{
    _viewportSize.x = drawableSize.width * _renderingQuality;
    _viewportSize.y = drawableSize.height * _renderingQuality;
    
    [self createMultisampleTexture];
    
    if (!_resolvingOnTileShaders)
    {
        _threadgroupsInGrid.width = (_viewportSize.x + _intrinsicThreadgroupSize.width - 1) / _intrinsicThreadgroupSize.width;
        _threadgroupsInGrid.height = (_viewportSize.y + _intrinsicThreadgroupSize.height - 1) / _intrinsicThreadgroupSize.height;
        _threadgroupsInGrid.depth = 1;
    }
}

#pragma mark - Antialiasing Control

- (void)updateAntialiasingInPipeline
{
    if (_antialiasingEnabled)
    {
        [self createMultisampleTextureDescriptor];
        [self createMultisampleTexture];
    }
    
    if (_antialiasingEnabled)
    {
        _renderPipelineDescriptor.sampleCount = _antialiasingSampleCount;
        _renderPipelineDescriptor.fragmentFunction = _fragmentFunctionNonHDR;
    }
    else
    {
        _renderPipelineDescriptor.sampleCount = 1;
        _renderPipelineDescriptor.fragmentFunction = _usesHDR ? _fragmentFunctionHDR : _fragmentFunctionNonHDR;
    }
    _renderPipelineState = [_device newRenderPipelineStateWithDescriptor:_renderPipelineDescriptor error:nil];
    
    if (_antialiasingEnabled)
    {
        [self updateResolveOptionInPipeline];
    }
}

- (void)updateResolveOptionInPipeline
{
    _usesHDR = _resolveOption == AAPLResolveOptionHDR;
    
    if (_resolvingOnTileShaders)
    {
        switch (_resolveOption)
        {
            case AAPLResolveOptionBuiltin:
                // When using a built-in resolve, the custom resolve pipeline isn't used.
                break;
            case AAPLResolveOptionAverage:
                _resolveTileRenderPipelineDescriptor.tileFunction = _averageResolveTileKernelFunction;
                break;
            case AAPLResolveOptionHDR:
                _resolveTileRenderPipelineDescriptor.tileFunction = _hdrResolveTileKernelFunction;
                break;
            default:
                break;
        }

        _resolveTileRenderPipelineDescriptor.rasterSampleCount = _antialiasingSampleCount;
        
        if (_resolveOption != AAPLResolveOptionBuiltin)
        {
            _resolveTileRenderPipelineState = [_device newRenderPipelineStateWithTileDescriptor:_resolveTileRenderPipelineDescriptor
                                                                                        options:0
                                                                                     reflection:nil
                                                                                          error:nil];
        }
    }
    else
    {
        switch (_resolveOption)
        {
            case AAPLResolveOptionBuiltin:
                // A custom resolve pipeline isn't necessary if the renderer uses the built-in resolve.
                break;
            case AAPLResolveOptionAverage:
                _resolveComputePipelineState = [_device newComputePipelineStateWithFunction:_averageResolveIMRKernelFunction
                                                                                      error:nil];
                break;
            case AAPLResolveOptionHDR:
                _resolveComputePipelineState = [_device newComputePipelineStateWithFunction:_hdrResolveIMRKernelFunction
                                                                                      error:nil];
                break;
            default:
                break;
        }
    }
}

#pragma mark - Setters

- (void)setResolvingOnTileShaders:(BOOL)resolveOnTileShaders
{
    NSAssert(self.supportsTileShaders || !resolveOnTileShaders,
             @"Cannot resolve on tile: Tile shaders not supported on this device.");
    
    _resolvingOnTileShaders = resolveOnTileShaders;
}

@end
