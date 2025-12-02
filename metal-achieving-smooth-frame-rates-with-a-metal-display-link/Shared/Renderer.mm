/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

#import "GameConfig.h"
#import "Renderer.h"
#import "MathUtilities.h"
#import "AssetLoader.h"

// Include the header shared between C code here, which executes Metal API commands, and `.metal` files.
#import "ShaderTypes.h"

// The renderer renders a maximum of two frames inflight when the maximum display link latency is 2.
static const NSUInteger MaxFramesInFlight = 2;

#if CREATE_DEPTH_BUFFER
static const MTLPixelFormat AAPLDepthPixelFormat = MTLPixelFormatDepth32Float;
#endif

@implementation Renderer
{
    id<MTLDevice> _device;
    id<MTLCommandQueue> _commandQueue;
    id<MTLCommandBuffer> _currentCommandBuffer;
    
    AssetLoader *_assetLoader;
    
    dispatch_semaphore_t _inFlightSemaphore;
    id<MTLBuffer> _frameDataBuffer[MaxFramesInFlight];
    
    id<MTLRenderPipelineState> _pipelineState;
    id<MTLDepthStencilState> _depthState;
    id<MTLTexture> _colorMap;
    id<MTLBuffer> _positionBuffer;
    id<MTLBuffer> _genericsBuffer;
    id<MTLBuffer> _indexBuffer;
    size_t _indexCount;
    
    size_t _frameDataBufferIndex;
    size_t _currentFrameIndex;
    
    simd_float4x4 _projectionMatrix;
    
    ModelConstantsData _modelConstants;
    
    // The render pass descriptor that creates a render command encoder to draw to the drawable
    // textures.
    MTLRenderPassDescriptor *_drawableRenderDescriptor;
    id <MTLTexture> _depthTarget;
}

// MARK: Initialization and setup methods.

- (nonnull instancetype)initWithMetalDevice:(nonnull id<MTLDevice>)device
                        drawablePixelFormat:(MTLPixelFormat)drawablePixelFormat;
{
    self = [super init];
    if (self)
    {
        _device = device;
        
        // Initialize the renderer-dependent view properties.
        _sampleCount = 1;
        _colorPixelFormat = drawablePixelFormat;
        _depthStencilPixelFormat = AAPLDepthPixelFormat;
        _depthStencilAttachmentTextureUsage = MTLTextureUsageRenderTarget;
        // The app ensures the final shader encodes its output values as PQ because it's using a 10-bit format.
        _colorspace = CGColorSpaceCreateWithName(kCGColorSpaceITUR_2100_PQ);
        
        // Create a semaphore to control the number of frames in flight.
        _inFlightSemaphore = dispatch_semaphore_create(MaxFramesInFlight);
        
        // Use the memoryless storage mode for the depth-stencil texture on supported devices.
        if ([_device supportsFamily:MTLGPUFamilyApple1])
        {
            // Set the depth-stencil texture to memoryless because the system doesn't use it in another render pass.
            _depthStencilStorageMode = MTLStorageModeMemoryless;
        }
        else
        {
            _depthStencilStorageMode = MTLStorageModePrivate;
        }
        
        // Create the command queue for creating command buffers.
        _commandQueue = [_device newCommandQueue];
        
        // Load the texture maps.
        _assetLoader = [[AssetLoader alloc] initWithDevice:_device];
        _colorMap = [_assetLoader loadTextureWithName:@"AssetFiles/ColorMap.png"];
        
        [self loadMetal];
        
        _state = [GameState new];
        
        _modelConstants.modelMatrix = matrix_identity_float4x4;
        _projectionMatrix = matrix_identity_float4x4;
        
        _currentFrameIndex = 0;
        
        _drawableRenderDescriptor = [MTLRenderPassDescriptor new];
        _drawableRenderDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _drawableRenderDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _drawableRenderDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 1, 1, 1);
        
#if CREATE_DEPTH_BUFFER
        _drawableRenderDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        _drawableRenderDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
        _drawableRenderDescriptor.depthAttachment.clearDepth = 1.0;
#endif
    }
    return self;
}

- (void)loadMetal
{
    // Initialize the per-frame constant data buffers.
    for (NSUInteger i = 0; i < MaxFramesInFlight; i++)
    {
        _frameDataBuffer[i] = [_device newBufferWithLength:sizeof(FrameData)
                                                   options:MTLResourceStorageModeShared];
        
        _frameDataBuffer[i].label = @"FrameDataBuffer";
    }
    
    // Configure the depth test.
    MTLDepthStencilDescriptor *depthStateDesc = [MTLDepthStencilDescriptor new];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];
    
    [self makeVertexBuffers];
    
    [self makeRenderPipelineState];
}

/// Makes the vertex buffers that store the vertex attributes for the scene geometry.
- (void)makeVertexBuffers
{
    /// A helper lambda to make a vertex's position.
    auto p = [](float x, float y, float z) -> VertexPosition {
        VertexPosition position{ { x, y, z } };
        return position;
    };
    
    /// A helper lambda to make a vertex's generic attributes.
    auto g = [](float s, float t, float nx, float ny, float nz) -> VertexGenerics {
        VertexGenerics generics { { s, t }, { nx, ny, nz } };
        return generics;
    };
    
    /// The vertex positions for a cube.
    static const VertexPosition cubePositions[] =
    {
        p( -1, -1,  1 ), p( -1,  1,  1 ), p(  1,  1,  1 ), p(  1, -1,  1 ), // Front
        p( -1,  1,  1 ), p( -1,  1, -1 ), p(  1,  1, -1 ), p(  1,  1,  1 ), // Top
        p(  1, -1,  1 ), p(  1,  1,  1 ), p(  1,  1, -1 ), p(  1, -1, -1 ), // Right
        p( -1,  1, -1 ), p( -1, -1, -1 ), p(  1, -1, -1 ), p(  1,  1, -1 ), // Back
        p( -1, -1, -1 ), p( -1, -1,  1 ), p(  1, -1,  1 ), p(  1, -1, -1 ), // Bottom
        p( -1, -1, -1 ), p( -1,  1, -1 ), p( -1,  1,  1 ), p( -1, -1,  1 ), // Left
    };
    
    _positionBuffer = [_device newBufferWithBytes:cubePositions
                                           length:sizeof(cubePositions)
                                          options:MTLStorageModeShared];
    _positionBuffer.label = @"positions";
    
    /// The texture coordinates and normals for a cube.
    static const VertexGenerics cubeGenerics[] = {
        g(0, 0, 0, 0, 1), g(0, 1, 0, 0, 1), g(1, 1, 0, 0, 1), g(1, 0, 0, 0, 1), // Front
        g(0, 0, 0, 1, 0), g(0, 1, 0, 1, 0), g(1, 1, 0, 1, 0), g(1, 0, 0, 1, 0), // Top
        g(0, 0, 1, 0, 0), g(0, 1, 1, 0, 0), g(1, 1, 1, 0, 0), g(1, 0, 1, 0, 0), // Right
        g(1, 0, 0, 0,-1), g(1, 1, 0, 0,-1), g(0, 1, 0, 0,-1), g(0, 0, 0, 0,-1), // Back
        g(0, 0, 0,-1, 0), g(0, 1, 0,-1, 0), g(1, 1, 0,-1, 0), g(1, 0, 0,-1, 0), // Bottom
        g(0, 0,-1, 0, 0), g(0, 1,-1, 0, 0), g(1, 1,-1, 0, 0), g(1, 0,-1, 0, 0), // Left
    };
    
    _genericsBuffer = [_device newBufferWithBytes:cubeGenerics
                                           length:sizeof(cubeGenerics)
                                          options:MTLStorageModeShared];
    _genericsBuffer.label = @"generics";
    
    /// The triangle indices for a cube.
    static uint16_t indices[] =
    {
        0,   2,  1,  0,  3,  2, // Front
        4,   6,  5,  4,  7,  6, // Top
        8,  10,  9,  8, 11, 10, // Right
        12, 14, 13, 12, 15, 14, // Back
        16, 18, 17, 16, 19, 18, // Bottom
        20, 22, 21, 20, 23, 22, // Left
    };
    
    _indexBuffer = [_device newBufferWithBytes:indices
                                        length:sizeof(indices)
                                       options:MTLStorageModeShared];
    _indexBuffer.label = @"indexBuffer";
    
    _indexCount = 36;
}

/// Sets the attribute and buffer layout for a vertex descriptor.
- (void)setAttributeLayoutForDescriptor:(nonnull MTLVertexDescriptor*)descriptor
                         attributeIndex:(NSUInteger)attributeIndex
                            bufferIndex:(NSUInteger)bufferIndex
                                 format:(MTLVertexFormat)format
                                 stride:(NSUInteger)stride
                                 offset:(NSUInteger)offset
{
    descriptor.attributes[attributeIndex].format = format;
    descriptor.attributes[attributeIndex].offset = offset;
    descriptor.attributes[attributeIndex].bufferIndex = bufferIndex;
    
    descriptor.layouts[bufferIndex].stride = stride;
    descriptor.layouts[bufferIndex].stepRate = 1;
    descriptor.layouts[bufferIndex].stepFunction = MTLVertexStepFunctionPerVertex;
}

/// Makes a render pipeline state object that the game uses to draw geometry with.
- (void)makeRenderPipelineState
{
    MTLVertexDescriptor *vertexDescriptor = [MTLVertexDescriptor new];
    
    [self setAttributeLayoutForDescriptor:vertexDescriptor
                           attributeIndex:VertexAttributePosition
                              bufferIndex:BufferIndexMeshPositions
                                   format:MTLVertexFormatFloat3
                                   stride:sizeof(VertexPosition)
                                   offset:offsetof(VertexPosition, position)];
    [self setAttributeLayoutForDescriptor:vertexDescriptor
                           attributeIndex:VertexAttributeTexcoord
                              bufferIndex:BufferIndexMeshGenerics
                                   format:MTLVertexFormatFloat2
                                   stride:sizeof(VertexGenerics)
                                   offset:offsetof(VertexGenerics, texcoord)];
    [self setAttributeLayoutForDescriptor:vertexDescriptor
                           attributeIndex:VertexAttributeNormal
                              bufferIndex:BufferIndexMeshGenerics
                                   format:MTLVertexFormatFloat3
                                   stride:sizeof(VertexGenerics)
                                   offset:offsetof(VertexGenerics, normal)];
    
    // Load the default library and create a render pipeline state object.
    id<MTLLibrary> library = [_device newDefaultLibrary];
    
    id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentShader"];
    
    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [MTLRenderPipelineDescriptor new];
    pipelineStateDescriptor.label = @"RenderPipeline";
    pipelineStateDescriptor.rasterSampleCount = _sampleCount;
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.vertexDescriptor = vertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = _colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = _depthStencilPixelFormat;
    
    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    
    if (!_pipelineState)
    {
        NSLog( @"Failed to create the render pipeline state: %@", error );
    }
}

// MARK: Rendering, updating, drawing, and resizing methods.

- (void)renderTo:(nonnull CAMetalLayer*)metalLayer
            with:(CAMetalDisplayLinkUpdate *_Nonnull)update
              at:(CFTimeInterval)deltaTime
{
    _currentFrameIndex++;
    
    id<CAMetalDrawable> currentDrawable = update.drawable;
    
    _drawableRenderDescriptor.colorAttachments[0].texture = currentDrawable.texture;
    
    [self renderUpdate:update with:_drawableRenderDescriptor to:currentDrawable at:deltaTime];
}

/// Updates and renders the graphics frame.
- (void)renderUpdate:(CAMetalDisplayLinkUpdate *_Nonnull)update
                with:(MTLRenderPassDescriptor *)renderPassDescriptor
                  to:(id<MTLDrawable>)currentDrawable
                  at:(CFTimeInterval)deltaTime
{
    // Update the game's state.
    [_state update:deltaTime];
    
    // Create a command buffer for drawing.
    [self prepareFrameToDraw];
    
    // Update the constant data buffers for the game.
    [self updateFrameDataBuffers];
    
    // Draw the frame.
    [self drawWith:renderPassDescriptor];
    
    // Finish the frame.
    [self presentAndCommitCommandBufferTo:currentDrawable];
}

/// Waits for a drawable to create a command buffer and prepares the time and index values for rendering.
- (void)prepareFrameToDraw
{
    // Wait to draw if a frame isn't available.
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommandBuffer";
    
    // Use the completion handler to signal the semaphore when the command buffer finishes.
    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer){
        dispatch_semaphore_signal(block_sema);
    }];
    _currentCommandBuffer = commandBuffer;
    
    // Prepare the time and index values needed by the rest of the update and drawing code.
    _currentFrameIndex += 1;
    _frameDataBufferIndex = _currentFrameIndex % MaxFramesInFlight;
}

/// Updates the game's state and GPU buffers before rendering.
- (void)updateFrameDataBuffers
{
    // Set the view and projection matrices in the frame constants data structure.
    simd_float4x4 viewMatrix = _state.viewMatrix;
    FrameData frameData;
    frameData.projectionMatrix = _projectionMatrix;
    frameData.viewMatrix = viewMatrix;
    frameData.projectionViewMatrix = simd_mul(_projectionMatrix, viewMatrix);
    frameData.normalizedLightDirection = simd_normalize(simd_make_float3(5.0, 5.0, 10.0));
    memcpy(_frameDataBuffer[_frameDataBufferIndex].contents, &frameData, sizeof(FrameData));
    
    // Concatenate the rotation matrix to the model's world matrix.
    simd_float4x4 R = matrix4x4_rotation(_state.rotationSpeed, simd_make_float3(0, 1, 0));
    _modelConstants.modelMatrix = simd_mul(_modelConstants.modelMatrix, R);
}

/// Draws a graphics image for the game to the view.
- (void)drawWith:(nonnull MTLRenderPassDescriptor *)renderPassDescriptor
{
    id<MTLCommandBuffer> commandBuffer = _currentCommandBuffer;
    if (!commandBuffer) {
        return;
    }
    
    // Clear the color attachment before rendering to the screen.
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    
    // Render the cube using a render command encoder.
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    if (!renderEncoder) {
        return;
    }
    renderEncoder.label = @"Primary Render Encoder";
    
    // Encode the commands that draw the box.
    
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    [renderEncoder setRenderPipelineState:_pipelineState];
    [renderEncoder setDepthStencilState:_depthState];
    
    [renderEncoder setVertexBuffer:_positionBuffer offset:0 atIndex:BufferIndexMeshPositions];
    [renderEncoder setVertexBuffer:_genericsBuffer offset:0 atIndex:BufferIndexMeshGenerics];
    [renderEncoder setVertexBuffer:_frameDataBuffer[_frameDataBufferIndex] offset:0 atIndex:BufferIndexFrameData];
    [renderEncoder setVertexBytes:&_modelConstants length:sizeof(ModelConstantsData) atIndex:BufferIndexModelConstants];
    [renderEncoder setFragmentTexture:_colorMap atIndex:TextureIndexColor];
    [renderEncoder setFragmentBuffer:_frameDataBuffer[_frameDataBufferIndex] offset:0 atIndex:BufferIndexFrameData];
    
    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                              indexCount:_indexCount
                               indexType:MTLIndexTypeUInt16
                             indexBuffer:_indexBuffer
                       indexBufferOffset:0];
    
    [renderEncoder endEncoding];
}

/// Commits the current command buffer to the drawable.
- (void)presentAndCommitCommandBufferTo:(nonnull id<MTLDrawable>)currentDrawable
{
    id<MTLCommandBuffer> commandBuffer = _currentCommandBuffer;
    if (!commandBuffer)
        return;
    
    [commandBuffer presentDrawable:currentDrawable];
    [commandBuffer commit];
    
    // Release the current command buffer.
    _currentCommandBuffer = nil;
}

/// Responds to the drawable's size or orientation changes.
- (void)drawableResize:(CGSize)drawableSize
{
    [self resize:drawableSize];
    [_state.gameInput drawableSizeDidChange:drawableSize];
    
#if CREATE_DEPTH_BUFFER
    MTLTextureDescriptor *depthTargetDescriptor = [MTLTextureDescriptor new];
    depthTargetDescriptor.width       = drawableSize.width;
    depthTargetDescriptor.height      = drawableSize.height;
    depthTargetDescriptor.pixelFormat = AAPLDepthPixelFormat;
    depthTargetDescriptor.storageMode = MTLStorageModePrivate;
    depthTargetDescriptor.usage       = MTLTextureUsageRenderTarget;
    
    _depthTarget = [_device newTextureWithDescriptor:depthTargetDescriptor];
    _drawableRenderDescriptor.depthAttachment.texture = _depthTarget;
#endif
}

- (void)resize:(CGSize)size
{
    const float aspect = (float)size.width / (float)size.height;
    const float fovYRadians = radiansFromDegrees(65.0f);
    _projectionMatrix = matrix4x4_perspective_right_hand(fovYRadians, aspect, 0.1f, 100.0f);
}

@end
