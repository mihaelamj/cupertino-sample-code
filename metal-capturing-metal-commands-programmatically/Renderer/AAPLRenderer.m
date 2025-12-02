/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

@import ModelIO;
#import "AAPLRenderer.h"
#import "AAPLShaderTypes.h"

static const NSUInteger kMaxBuffersInFlight = 3;

static const size_t kAlignedUniformsSize = (sizeof(Uniforms) & ~0xFF) + 0x100;

@implementation AAPLRenderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;

    id <MTLBuffer> _dynamicUniformBuffer;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    id <MTLTexture> _colorMap;
    MTLVertexDescriptor *_mtlVertexDescriptor;

    uint32_t _uniformBufferOffset;

    uint8_t _uniformBufferIndex;

    void* _uniformBufferAddress;

    matrix_float4x4 _projectionMatrix;

    float _rotation;

    MTKMesh *_mesh;
}

#pragma mark - Initialization and Setup Methods

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view
{
    self = [super init];
    if (self)
    {
        _device = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(kMaxBuffersInFlight);
        
        // Setup the MetalKit view and Metal objects.
        [self _loadMetalWithView:view];
        
        // Load the model assets.
        [self _loadAssets];
    }

    return self;
}

- (void)_loadMetalWithView:(nonnull MTKView *)view;
{
    // Initialize the renderer-dependent view properties.
    view.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    view.sampleCount = 1;

    // Configure the vertex descriptor.
    [self createVertexDescriptor];

    // Load the default library and create a render pipeline state object.
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
    [self createPipelineStateBase:view shaderLibrary:defaultLibrary];

    // Configure the depth test.
    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

    // Create a buffer to store uniform data.
    NSUInteger uniformBufferSize = kAlignedUniformsSize * kMaxBuffersInFlight;
    _dynamicUniformBuffer = [_device newBufferWithLength:uniformBufferSize
                                                 options:MTLResourceStorageModeShared];
    _dynamicUniformBuffer.label = @"UniformBuffer";

    // Create a command queue.
    _commandQueue = [_device newCommandQueue];

    // Initialize the capture manager.
    _captureManager = [[AAPLCaptureManager alloc] init];
}

- (void)createVertexDescriptor
{
    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    _mtlVertexDescriptor.attributes[VertexAttributePosition].format = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].offset = 0;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;

    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].offset = 0;
    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshGenerics;

    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride = 12;
    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stride = 8;
    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepRate = 1;
    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;
}

- (void)createPipelineStateBase:(MTKView*)view shaderLibrary:(id<MTLLibrary>)shaderLibrary
{
    id <MTLFunction> vertexFunction = [shaderLibrary newFunctionWithName:@"vertexShader"];
    id <MTLFunction> fragmentFunction = [shaderLibrary newFunctionWithName:@"fragmentShader"];

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"RenderPipeline";
    pipelineStateDescriptor.sampleCount = view.sampleCount;
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
    pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;

    NSError *error = NULL;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];

    NSAssert(_pipelineState, @"Failed to create the render pipeline state, error: %@.", error);
}

- (void)_loadAssets
{
    NSError *error;

    // Load the model mesh.
    MTKMeshBufferAllocator *metalAllocator = [[MTKMeshBufferAllocator alloc]
                                              initWithDevice: _device];

    MDLMesh *mdlMesh = [MDLMesh newBoxWithDimensions:(vector_float3){4, 4, 4}
                                            segments:(vector_uint3){2, 2, 2}
                                        geometryType:MDLGeometryTypeTriangles
                                       inwardNormals:NO
                                           allocator:metalAllocator];

    MDLVertexDescriptor *mdlVertexDescriptor =
    MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor);

    mdlVertexDescriptor.attributes[VertexAttributePosition].name  = MDLVertexAttributePosition;
    mdlVertexDescriptor.attributes[VertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;

    mdlMesh.vertexDescriptor = mdlVertexDescriptor;

    _mesh = [[MTKMesh alloc] initWithMesh:mdlMesh
                                   device:_device
                                    error:&error];

    if (!_mesh || error)
    {
        NSLog(@"Error creating the MetalKit mesh, error: %@.", error.localizedDescription);
    }

    // Load the model texture.
    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];

    NSDictionary *textureLoaderOptions =
    @{
        MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
        MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
     };

    _colorMap = [textureLoader newTextureWithName:@"ColorMap"
                                      scaleFactor:1.0
                                           bundle:nil
                                          options:textureLoaderOptions
                                            error:&error];

    if (!_colorMap || error)
    {
        NSLog(@"Error creating the Metal texture, error: %@.", error.localizedDescription);
    }
}

#pragma mark - Data Update Methods

- (void)_updateDynamicBufferState
{
    // Update the data in the uniform buffers before rendering the next frame.
    
    _uniformBufferIndex = (_uniformBufferIndex + 1) % kMaxBuffersInFlight;
    _uniformBufferOffset = kAlignedUniformsSize * _uniformBufferIndex;
    _uniformBufferAddress = ((uint8_t*)_dynamicUniformBuffer.contents) + _uniformBufferOffset;
}

- (void)_updateSceneState
{
    // Update data for the scene before encoding any commands that render to a drawable.

    Uniforms * uniforms = (Uniforms*)_uniformBufferAddress;

    uniforms->projectionMatrix = _projectionMatrix;

    vector_float3 rotationAxis = {1, 1, 0};
    matrix_float4x4 modelMatrix = matrix4x4_rotation(_rotation, rotationAxis);
    matrix_float4x4 viewMatrix = matrix4x4_translation(0.0, 0.0, -8.0);

    uniforms->modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);

    _rotation += .01;
}

#pragma mark - Render Methods

// Draw the current scene.
- (void)drawScene:(nonnull MTKView *)view
{
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommandBuffer";

    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
        {
            dispatch_semaphore_signal(block_sema);
        }];

    [self _updateDynamicBufferState];

    [self _updateSceneState];

    // Obtain a render pass descriptor generated from the view's drawable textures.
    // Get `currentRenderPassDescriptor` as late as possible in the frame, to avoid holding
    // a drawable and blocking the display pipeline any longer than necessary.
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

    // If you obtained a valid render pass descriptor, render to the drawable. Otherwise,
    // skip any rendering for this frame because there is no drawable to draw to.
    if (renderPassDescriptor != nil) {

        id <MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderCommandEncoder";

        // Mark the start of the commands that draw the box.
        // Note: If you encode a `pushDebugGroup` command, you must encode a respective
        // `popDebugGroup` command to fully encapsulate the commands between these two
        // endpoint marks.
        [renderEncoder pushDebugGroup:@"DrawBox"];

        // Encode the commands that draw the box.
        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];

        [renderEncoder setVertexBuffer:_dynamicUniformBuffer
                                offset:_uniformBufferOffset
                               atIndex:BufferIndexUniforms];

        [renderEncoder setFragmentBuffer:_dynamicUniformBuffer
                                  offset:_uniformBufferOffset
                                 atIndex:BufferIndexUniforms];

        for (NSUInteger bufferIndex = 0; bufferIndex < _mesh.vertexBuffers.count; bufferIndex++)
        {
            MTKMeshBuffer *vertexBuffer = _mesh.vertexBuffers[bufferIndex];
            if ((NSNull*)vertexBuffer != [NSNull null])
            {
                [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                        offset:vertexBuffer.offset
                                       atIndex:bufferIndex];
            }
        }

        [renderEncoder setFragmentTexture:_colorMap
                                  atIndex:TextureIndexColor];

        for (MTKSubmesh *submesh in _mesh.submeshes)
        {
            [renderEncoder drawIndexedPrimitives:submesh.primitiveType
                                      indexCount:submesh.indexCount
                                       indexType:submesh.indexType
                                     indexBuffer:submesh.indexBuffer.buffer
                               indexBufferOffset:submesh.indexBuffer.offset];
        }

        // Mark the end of the commands that draw the box.
        // Note: This command pops the `DrawBox` marker.
        [renderEncoder popDebugGroup];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

#pragma mark - MTKView Delegate Methods

- (void)drawInMTKView:(nonnull MTKView *)view
{
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    
    if (self.captureManager.captureDescriptor != nil) {
        // If the user initiated a capture sequence, start a new capture.
        [self.captureManager startCapture];
    }
    
    // Draw the scene.
    [self drawScene:view];
    
    if (self.captureManager.captureDescriptor != nil) {
        // If the user initiated a capture sequence, stop the current capture.
        [self.captureManager stopCapture];
    }
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    float aspect = size.width / (float)size.height;
    _projectionMatrix = matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
}

#pragma mark - Matrix Math Utility Methods

matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz)
{
    return (matrix_float4x4) {{
        { 1,   0,  0,  0 },     // Column 0.
        { 0,   1,  0,  0 },     // Column 1.
        { 0,   0,  1,  0 },     // Column 2.
        { tx, ty, tz,  1 }      // Column 3.
    }};
}

static matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis)
{
    axis = vector_normalize(axis);
    float ct = cosf(radians);
    float st = sinf(radians);
    float ci = 1 - ct;
    float x = axis.x, y = axis.y, z = axis.z;

    return (matrix_float4x4) {{
        { ct + x * x * ci,     y * x * ci + z * st, z * x * ci - y * st, 0},    // Column 0.
        { x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0},    // Column 1.
        { x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0},    // Column 2.
        {                   0,                   0,                   0, 1}     // Column 3.
    }};
}

matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);

    return (matrix_float4x4) {{
        { xs,   0,          0,  0 },    // Column 0.
        {  0,  ys,          0,  0 },    // Column 1.
        {  0,   0,         zs, -1 },    // Column 2.
        {  0,   0, nearZ * zs,  0 }     // Column 3.
    }};
}

@end

