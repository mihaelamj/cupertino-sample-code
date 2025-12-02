/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A platform independent renderer class
*/

#import <simd/simd.h>
#import <ModelIO/ModelIO.h>

#import "Renderer.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "ShaderTypes.h"

static const NSUInteger MaxBuffersInFlight = 3;
static const NSUInteger NumConstantDataBuffers = 13;
static const NSUInteger NumObjects = 2;
static const NSUInteger NumFloatValues = 100;

#if TARGET_OS_SIMULATOR || TARGET_MACOS
static const NSUInteger RequiredConstantBufferAlignment = 256;
#else
static const NSUInteger RequiredConstantBufferAlignment = 4;
#endif

#define MAX_ALIGNMENT(A, B) ((A > B) ? A : B)

// The aligned size of our uniform structure
static const NSUInteger UniformsConstantBufferAlignment = MAX_ALIGNMENT(_Alignof(Uniforms), RequiredConstantBufferAlignment);
static const NSUInteger AlignedUniformsSize = (sizeof(Uniforms) & ~(UniformsConstantBufferAlignment - 1)) + UniformsConstantBufferAlignment;

@implementation Renderer
{
    dispatch_semaphore_t _inFlightSemaphore;
    id <MTLDevice> _device;
    id <MTLCommandQueue> _commandQueue;

    id <MTLTexture> _depthTexture;
    id <MTLTexture> _stencilTexture;

    id <MTLBuffer> _dynamicUniformBuffer[MaxBuffersInFlight];
    id <MTLBuffer> _constantData[NumConstantDataBuffers];
    id <MTLBuffer>  _linearTextureBacking;
    id <MTLTexture> _linearTexture;
    id <MTLTexture> _msaaTexture;

    id <MTLRenderPipelineState> _pipelineState;
#if TARGET_OS_SIMULATOR || TARGET_MACOS
    id <MTLRenderPipelineState> _blendPipelineState;
#endif
    id <MTLDepthStencilState> _depthState;
    id <MTLTexture> _colorMap;
    MTLVertexDescriptor *_mtlVertexDescriptor;

    uint8_t _uniformBufferIndex;

    matrix_float4x4 _projectionMatrix;

    float _rotation;

    MTKMesh *_meshes[NumObjects];
    
    float _transparency;
    BlendMode _currentBlendMode;
}

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view
{
    self = [super init];
    if(self)
    {
        _device = view.device;
        _inFlightSemaphore = dispatch_semaphore_create(MaxBuffersInFlight);
        [self loadMetalWithView:view];
        [self loadAssets];
        _transparency = 0.5;
        _currentBlendMode = BlendModeTransparency;
#if TARGET_OS_SIMULATOR || TARGET_MACOS
        view.framebufferOnly = NO;
#endif
    }

    return self;
}

NSUInteger alignTo(const NSUInteger alignment, const NSUInteger value)
{
    return (value + (alignment - 1)) & ~(alignment - 1);
}

- (void) writeLinearTextureData:(void *)dstPtr textureWidth:(NSUInteger)textureWidth
                  textureHeight:(NSUInteger)textureHeight bytesPerRow:(size_t)bytesPerRow
{
    // Initialize all pixels to red
    for(int y = 0; y < textureHeight; y++)
    {
        vector_uint4 *curPixel = (vector_uint4 *)((char *)dstPtr + bytesPerRow * y);
        for(int x = 0; x < textureWidth; x++)
        {
            curPixel->x = 255;
            curPixel->y = 0;
            curPixel->z = 0;
            curPixel->w = 255;
            curPixel++;
        }
    }
}

- (void) initializeLinearTextureData:(id <MTLBuffer>)backingBuffer textureWidth:(NSUInteger)textureWidth
                       textureHeight:(NSUInteger)textureHeight bytesPerRow:(size_t)bytesPerRow
{
    if(backingBuffer.storageMode == MTLStorageModePrivate)
    {
        // Create a shared buffer, initialize the shared buffer's data,
        // and blit the shared texture to the linear texture's backing buffer
        const NSUInteger bytesPerImage = bytesPerRow * textureHeight;
        id <MTLBuffer> tmpBuffer = [_device newBufferWithLength:bytesPerImage options:MTLResourceStorageModeShared];
        [self writeLinearTextureData:tmpBuffer.contents textureWidth:textureWidth textureHeight:textureHeight bytesPerRow:bytesPerRow];
        
        id <MTLCommandBuffer> blitCommandBuffer = [_commandQueue commandBuffer];
        id <MTLBlitCommandEncoder> blitEncoder = [blitCommandBuffer blitCommandEncoder];
        
        [blitEncoder copyFromBuffer:tmpBuffer sourceOffset:0
                           toBuffer:backingBuffer destinationOffset:0 size:bytesPerImage];
        
        [blitEncoder endEncoding];
        [blitCommandBuffer commit];
        [blitCommandBuffer waitUntilCompleted];
    }
    else
    {
        // memcpy is only allowed for shared buffers
        [self writeLinearTextureData:backingBuffer.contents textureWidth:textureWidth textureHeight:textureHeight bytesPerRow:bytesPerRow];
    }
}

- (void) initializeLinearTexture
{
#if TARGET_OS_SIMULATOR || TARGET_MACOS
    MTLResourceOptions options = MTLResourceStorageModePrivate;
#else
    MTLResourceOptions options = MTLResourceStorageModeShared;
#endif
    const NSUInteger textureWidth = 256, textureHeight = 512;
    const NSUInteger pixelSize = 4 * sizeof(uint32_t);

    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor new];
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA32Uint;
    textureDescriptor.width = textureWidth;
    textureDescriptor.height = textureHeight;
    textureDescriptor.resourceOptions = options;
    
    const NSUInteger requiredAlignment = [_device minimumLinearTextureAlignmentForPixelFormat:textureDescriptor.pixelFormat];
    NSUInteger bytesPerRow =  alignTo(requiredAlignment, textureWidth * pixelSize);
    NSUInteger bytesPerImage = bytesPerRow * textureHeight;
    
    _linearTextureBacking = [_device newBufferWithLength:bytesPerImage options:options];
    _linearTexture = [_linearTextureBacking newTextureWithDescriptor:textureDescriptor
                                                              offset:0
                                                         bytesPerRow:bytesPerRow];

    [self initializeLinearTextureData:_linearTextureBacking textureWidth:textureWidth textureHeight:textureHeight bytesPerRow:bytesPerRow];
}

- (void) initializeDepthStencilTextures:(nonnull MTKView *)view
{
#if TARGET_OS_SIMULATOR || TARGET_MACOS
    const MTLPixelFormat DepthFormat = MTLPixelFormatDepth32Float_Stencil8;
    const MTLPixelFormat StencilFormat = MTLPixelFormatDepth32Float_Stencil8;
    const MTLStorageMode StorageMode = MTLStorageModePrivate;
#else
    const MTLPixelFormat DepthFormat = MTLPixelFormatDepth32Float;
    const MTLPixelFormat StencilFormat = MTLPixelFormatStencil8;
    const MTLStorageMode StorageMode = MTLStorageModeShared;
#endif
    
    MTLTextureDescriptor *depthStencilTextureDescriptor = [MTLTextureDescriptor new];
    depthStencilTextureDescriptor.textureType = MTLTextureType2D;
    depthStencilTextureDescriptor.width = view.drawableSize.width;
    depthStencilTextureDescriptor.height = view.drawableSize.height;
    depthStencilTextureDescriptor.pixelFormat = DepthFormat;
    depthStencilTextureDescriptor.usage = MTLTextureUsageRenderTarget;
    depthStencilTextureDescriptor.storageMode = StorageMode;

    _depthTexture = [_device newTextureWithDescriptor:depthStencilTextureDescriptor];
    if(DepthFormat != StencilFormat)
    {
        depthStencilTextureDescriptor.pixelFormat = StencilFormat;
        _stencilTexture = [_device newTextureWithDescriptor:depthStencilTextureDescriptor];
    }
    else
    {
        _stencilTexture = _depthTexture;
    }
}

- (void)loadMetalWithView:(nonnull MTKView *)view
{
    /// Load Metal state objects and initalize renderer dependent view properties

    _commandQueue = [_device newCommandQueue];

    [self initializeDepthStencilTextures:view];
    
    view.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    view.sampleCount = 1;
    
    _mtlVertexDescriptor = [[MTLVertexDescriptor alloc] init];

    _mtlVertexDescriptor.attributes[VertexAttributePosition].format = MTLVertexFormatFloat3;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].offset = 0;
    _mtlVertexDescriptor.attributes[VertexAttributePosition].bufferIndex = BufferIndexMeshPositions;

    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].format = MTLVertexFormatFloat2;
    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].offset = 0;
    _mtlVertexDescriptor.attributes[VertexAttributeTexcoord].bufferIndex = BufferIndexMeshGenerics;

    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stride = sizeof(float) * 3; // float3 is a packed type
    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepRate = 1;
    _mtlVertexDescriptor.layouts[BufferIndexMeshPositions].stepFunction = MTLVertexStepFunctionPerVertex;

    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stride = sizeof(vector_float2);
    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepRate = 1;
    _mtlVertexDescriptor.layouts[BufferIndexMeshGenerics].stepFunction = MTLVertexStepFunctionPerVertex;

    id <MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

    id <MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexShader"];

    id <MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentShader"];

    MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineStateDescriptor.label = @"MyPipeline";
    pipelineStateDescriptor.sampleCount = view.sampleCount;
    pipelineStateDescriptor.vertexFunction = vertexFunction;
    pipelineStateDescriptor.fragmentFunction = fragmentFunction;
    pipelineStateDescriptor.vertexDescriptor = _mtlVertexDescriptor;
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
    pipelineStateDescriptor.depthAttachmentPixelFormat = _depthTexture.pixelFormat;
    pipelineStateDescriptor.stencilAttachmentPixelFormat = _stencilTexture.pixelFormat;
    
    NSError *error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];

    NSAssert(_pipelineState, @"Failed to create pipeline state: %@", error);

#if TARGET_OS_SIMULATOR || TARGET_MACOS
    id <MTLFunction> blendFragmentFunction = [defaultLibrary newFunctionWithName:@"blendFragmentShader"];
    assert(blendFragmentFunction);
    pipelineStateDescriptor.fragmentFunction = blendFragmentFunction;
    _blendPipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
    NSAssert(_blendPipelineState, @"Failed to create blend pipeline state: %@", error);
#endif

    MTLDepthStencilDescriptor *depthStateDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStateDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStateDesc.depthWriteEnabled = YES;
    _depthState = [_device newDepthStencilStateWithDescriptor:depthStateDesc];

    for(NSUInteger i = 0; i < MaxBuffersInFlight; i++)
    {
        _dynamicUniformBuffer[i] = [_device newBufferWithLength:AlignedUniformsSize * NumObjects
                                                        options:MTLResourceStorageModeShared];

        _dynamicUniformBuffer[i].label = @"UniformBuffer";
    }
    
    const NSUInteger constantBufferLength = sizeof(vector_float4) * NumFloatValues;
#if TARGET_OS_SIMULATOR || TARGET_MACOS
    const NSUInteger maxConstantBufferLength = 64 * 1024; // 64KB
    assert(constantBufferLength < maxConstantBufferLength);
#endif

    for(int i = 0; i < NumConstantDataBuffers; i++)
    {
        _constantData[i] = [_device newBufferWithLength:constantBufferLength
                                                options:MTLResourceStorageModeShared];
    }

    [self initializeLinearTexture];
    
    MTLTextureDescriptor *msaaTextureDescriptor = [MTLTextureDescriptor new];
    msaaTextureDescriptor.textureType = MTLTextureType2DMultisample;
    msaaTextureDescriptor.width = 1024;
    msaaTextureDescriptor.height = 1024;
    msaaTextureDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
#if TARGET_OS_SIMULATOR || TARGET_MACOS
    msaaTextureDescriptor.sampleCount = 4;
    msaaTextureDescriptor.storageMode = MTLStorageModePrivate;
#else
    msaaTextureDescriptor.sampleCount = 2;
    msaaTextureDescriptor.storageMode = MTLStorageModeShared;
#endif
    _msaaTexture = [_device newTextureWithDescriptor:msaaTextureDescriptor];
}

- (MTKMesh *)createBoxMeshWithDimensions:(vector_float3)dimensions segments:(vector_uint3)segments allocator:(MTKMeshBufferAllocator *)metalAllocator
{
    NSError *error;
    MDLMesh *mdlMesh = [MDLMesh newBoxWithDimensions:(vector_float3)dimensions
                                            segments:(vector_uint3)segments
                                        geometryType:MDLGeometryTypeTriangles
                                       inwardNormals:NO
                                           allocator:metalAllocator];
    
    MDLVertexDescriptor *mdlVertexDescriptor =
    MTKModelIOVertexDescriptorFromMetal(_mtlVertexDescriptor);
    
    mdlVertexDescriptor.attributes[VertexAttributePosition].name  = MDLVertexAttributePosition;
    mdlVertexDescriptor.attributes[VertexAttributeTexcoord].name  = MDLVertexAttributeTextureCoordinate;
    
    mdlMesh.vertexDescriptor = mdlVertexDescriptor;
    
    MTKMesh *mesh = [[MTKMesh alloc] initWithMesh:mdlMesh device:_device error:&error];

    NSAssert(mesh, @"Failed to create MetalKit Mesh: %@", error);

    return mesh;
}

- (id <MTLTexture>)loadTexture:(NSString *)name textureLoader:(MTKTextureLoader *)textureLoader
{
    NSError *error;
    NSDictionary *textureLoaderOptions =
    @{
          MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
          MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
      };
    id <MTLTexture> tex = [textureLoader newTextureWithName:name
                                         scaleFactor:1.0
                                              bundle:nil
                                             options:textureLoaderOptions
                                               error:&error];

    NSAssert(tex, @"Failed to create texture (%@): %@", name, error);

    return tex;
}

- (void)loadAssets
{
    /// Load assets into metal objects
    MTKMeshBufferAllocator *metalAllocator = [[MTKMeshBufferAllocator alloc]
                                              initWithDevice: _device];

    _meshes[0] = [self createBoxMeshWithDimensions:(vector_float3){3, 3, 3}
                                          segments:(vector_uint3){2, 2, 2}
                                         allocator:metalAllocator];
    _meshes[1] = [self createBoxMeshWithDimensions:(vector_float3){3, 3, 3}
                                          segments:(vector_uint3){2, 2, 2}
                                         allocator:metalAllocator];

    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
    _colorMap = [self loadTexture:@"ColorMap" textureLoader:textureLoader];
}

-(void)setTransparency:(float)value
{
    _transparency = value;
}

-(void)setBlendMode:(BlendMode)mode
{
    _currentBlendMode = mode;
}

- (void)updateState
{
    /// Update any game state before encoding renderint commands to our drawable
    {
        Uniforms * uniforms = (Uniforms*)_dynamicUniformBuffer[_uniformBufferIndex].contents;

        uniforms->projectionMatrix = _projectionMatrix;
        uniforms->forceColor = NO;
        uniforms->color = (vector_float4){1.0, 0.0, 0.0, 1.0};
        uniforms->blendMode = BlendModeNone;
        uniforms->transparency = 0;
        
        vector_float3 rotationAxis = {1, 1, 0};
        matrix_float4x4 modelMatrix =  matrix_multiply(matrix4x4_translation(0,-1,0), matrix4x4_rotation(_rotation, rotationAxis));
        matrix_float4x4 viewMatrix = matrix4x4_translation(0.0, 0.0, -8.0);

        uniforms->modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);
    }
    {
        Uniforms * uniforms = (Uniforms*)((char *)_dynamicUniformBuffer[_uniformBufferIndex].contents + AlignedUniformsSize);
        uniforms->projectionMatrix = _projectionMatrix;
        uniforms->forceColor = YES;
        uniforms->color = (vector_float4){0.0, 0.0, 1.0, 1.0};
        uniforms->blendMode = (uint32_t)_currentBlendMode;
        uniforms->transparency = _transparency;
        
        vector_float3 rotationAxis = {1, 1, 0};
        matrix_float4x4 modelMatrix = matrix_multiply(matrix4x4_translation(1,0,1), matrix4x4_rotation(_rotation, rotationAxis));
        matrix_float4x4 viewMatrix = matrix4x4_translation(0.0, 0.0, -8.0);
        
        uniforms->modelViewMatrix = matrix_multiply(viewMatrix, modelMatrix);
    }

    _rotation += .01;
}

- (void)bindVertexDescriptorsForMesh:(MTKMesh *)mesh renderEncoder:(id <MTLRenderCommandEncoder>)renderEncoder
{
    for (NSUInteger bufferIndex = 0; bufferIndex < mesh.vertexBuffers.count; bufferIndex++)
    {
        MTKMeshBuffer *vertexBuffer = mesh.vertexBuffers[bufferIndex];
        if((NSNull*)vertexBuffer != [NSNull null])
        {
            [renderEncoder setVertexBuffer:vertexBuffer.buffer
                                    offset:vertexBuffer.offset
                                   atIndex:bufferIndex];
        }
    }
}

- (void)drawBox:(NSUInteger)boxIndex renderEncoder:(id <MTLRenderCommandEncoder>)renderEncoder
{
    assert(boxIndex < NumObjects);
        
    [renderEncoder setVertexBuffer:_dynamicUniformBuffer[_uniformBufferIndex]
                            offset:boxIndex * AlignedUniformsSize
                           atIndex:BufferIndexUniforms];
    
    [renderEncoder setFragmentBuffer:_dynamicUniformBuffer[_uniformBufferIndex]
                              offset:boxIndex * AlignedUniformsSize
                             atIndex:BufferIndexUniforms];
    
    NSUInteger constantBufferIndex = BufferIndexUniforms + 1;
    NSUInteger constantBufferOffset = sizeof(vector_float4) * 16;
    
    assert((constantBufferOffset & (RequiredConstantBufferAlignment - 1)) == 0);

    for(int i = 0; i < NumConstantDataBuffers; i++)
    {
        [renderEncoder setFragmentBuffer:_constantData[i]
                                  offset:constantBufferOffset
                                 atIndex:constantBufferIndex++];
    }
    
    [renderEncoder setFragmentTexture:_colorMap
                              atIndex:TextureIndexColor];
    
    [renderEncoder setFragmentTexture:_linearTexture
                              atIndex:TextureIndexLinear];
    
    [renderEncoder setFragmentTexture:_msaaTexture
                              atIndex:TextureIndexMSAA];
    
    for(MTKSubmesh *submesh in _meshes[boxIndex].submeshes)
    {
        [renderEncoder drawIndexedPrimitives:submesh.primitiveType
                                  indexCount:submesh.indexCount
                                   indexType:submesh.indexType
                                 indexBuffer:submesh.indexBuffer.buffer
                           indexBufferOffset:submesh.indexBuffer.offset];
    }
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    /// Per frame updates here

    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);

    _uniformBufferIndex = (_uniformBufferIndex) % (MaxBuffersInFlight);

    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"MyCommand";

    __block dispatch_semaphore_t block_sema = _inFlightSemaphore;
    [commandBuffer addCompletedHandler:^(id <MTLCommandBuffer> buffer)
     {
         dispatch_semaphore_signal(block_sema);
     }];

    [self updateState];
    
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

#if TARGET_OS_SIMULATOR || TARGET_MACOS
    // We need to ensure that the current render encoder's attachments are stored for the next encoder to load
    renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
    renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionStore;
    renderPassDescriptor.stencilAttachment.storeAction = MTLStoreActionStore;
#endif

    renderPassDescriptor.depthAttachment.texture = _depthTexture;
    renderPassDescriptor.stencilAttachment.texture = _stencilTexture;

    if(renderPassDescriptor != nil)
    {
        /// Final pass rendering code here
        id <MTLRenderCommandEncoder> renderEncoder = nil;
        renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        renderEncoder.label = @"MyRenderEncoder";
        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_pipelineState];
        [renderEncoder setDepthStencilState:_depthState];

        [self bindVertexDescriptorsForMesh:_meshes[0] renderEncoder:renderEncoder];
        [self drawBox:0 renderEncoder:renderEncoder];

#if TARGET_OS_SIMULATOR || TARGET_MACOS
        [renderEncoder endEncoding];
        
        renderPassDescriptor = view.currentRenderPassDescriptor;

        // We need to ensure that the previous render encoder's attachments are loaded
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
        renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionLoad;
        renderPassDescriptor.stencilAttachment.loadAction = MTLLoadActionLoad;
        renderPassDescriptor.depthAttachment.texture = _depthTexture;
        renderPassDescriptor.stencilAttachment.texture = _stencilTexture;
        
        renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        renderEncoder.label = @"MyRenderEncoder_2";
        [renderEncoder pushDebugGroup:@"DrawBox_2"];
        [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
        [renderEncoder setCullMode:MTLCullModeBack];
        [renderEncoder setRenderPipelineState:_blendPipelineState];
        [renderEncoder setDepthStencilState:_depthState];
        
        [renderEncoder setFragmentTexture:view.currentRenderPassDescriptor.colorAttachments[0].texture
                                  atIndex:TextureIndexFB];
#endif
        
        [self bindVertexDescriptorsForMesh:_meshes[1] renderEncoder:renderEncoder];
        [self drawBox:1 renderEncoder:renderEncoder];

        [renderEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    /// Respond to drawable size or orientation changes here

    float aspect = size.width / (float)size.height;
    _projectionMatrix = matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
}

#pragma mark Matrix Math Utilities

matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz)
{
    return (matrix_float4x4) {{
        { 1,   0,  0,  0 },
        { 0,   1,  0,  0 },
        { 0,   0,  1,  0 },
        { tx, ty, tz,  1 }
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
        { ct + x * x * ci,     y * x * ci + z * st, z * x * ci - y * st, 0},
        { x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0},
        { x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0},
        {                   0,                   0,                   0, 1}
    }};
}

matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);

    return (matrix_float4x4) {{
        { xs,   0,          0,  0 },
        {  0,  ys,          0,  0 },
        {  0,   0,         zs, -1 },
        {  0,   0, nearZ * zs,  0 }
    }};
}

@end
