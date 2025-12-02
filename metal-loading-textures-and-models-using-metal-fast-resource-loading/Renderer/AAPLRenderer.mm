/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

#include <thread>
#include <atomic>

#import <Metal/Metal.h>

#import "AAPLConfig.h"
#import "Shaders/AAPLShaderTypes.h"
#import "AAPLKTXTextureResource.hpp"
#import "AAPLMathUtilities.h"
#import "AAPLRenderer.h"

static const NSUInteger AAPLMaxFramesInFlight = 3;
static const NSUInteger AAPLNumObjects = 3;

enum ResourceDetailIndex {
    SmallIndex,
    LargeIndex,
    NumDetailLevels
};

enum LoadStatus
{
    LoadStatusSmallResourceLoaded,
    LoadStatusLargeResourceLoading,
    LoadStatusLargeResourceLoaded,
};

typedef struct AAPLModelBufferFileHeader
{
    char magic[8];
    size_t bufferSizeInBytes;      // The size of the Metal buffer to allocate.
    size_t vertexFileOffset;       // The location in the file where the vertex buffer starts.
    size_t vertexSizeInBytes;      // The size of the Vertex section of the buffer.
    size_t vertexCount;            // The number of vertices.
    size_t vertexPositionsOffset;  // The offset into the Metal buffer where the positions start.
    size_t vertexNormalsOffset;    // The offset into the Metal buffer where the normals start.
    size_t vertexTexcoordOffset;   // The offset into the Metal buffer where the texture coordinates start.
    size_t indexSizeInBytes;       // The size of the Index section of the buffer.
    size_t indexFileOffset;        // The location in the file where the index buffer starts.
    size_t indexCount;             // The number of triangle indices.
    size_t indexOffset;            // The location into the Metal buffer where the indices start.
} AAPLModelBufferFileHeader;

template <typename T>
struct AAPLResourceCommon
{
    /// Store the index of the resource to use, where 0 = low-resolution and 1 = high-resolution.
    ResourceDetailIndex currentIndex;
    /// Use the preferred index to start loading the high-resolution resource.
    ResourceDetailIndex preferredIndex;
    /// Store the current state of the buffer and texture.
    enum LoadStatus loadStatus;
    
    /// The low-resolution resource (index 0) is always resident and the high-resolution resource (index = 1) is sometimes resident.
    T resources[NumDetailLevels];
    /// Store the URLs for this resource for streaming purposes.
    NSURL* urls[NumDetailLevels];
    
#if AAPL_USE_MTLIO
    /// Store the MTLIO file handles to avoid opening them every time.
    id<MTLIOFileHandle> handles[NumDetailLevels];
#endif

    /// Unload the high-resolution resource and switch to the low-resolution resource.
    inline void unload()
    {
        if (preferredIndex == SmallIndex && resources[LargeIndex])
        {
            resources[LargeIndex] = nil;
            currentIndex = SmallIndex;
            loadStatus = LoadStatusSmallResourceLoaded;
        }
    }
    
    /// Stage the resource for loading and return 1 if the resource needs to be loaded.
    inline size_t stage()
    {
        if (preferredIndex == LargeIndex && resources[LargeIndex] == nil)
        {
            if (loadStatus == LoadStatusSmallResourceLoaded)
            {
                loadStatus = LoadStatusLargeResourceLoading;
                return 1;
            }
        }
        return 0;
    }
    
    /// If the resource was loading, mark it as loaded.
    inline void setLoaded()
    {
        if (loadStatus == LoadStatusLargeResourceLoading)
        {
            loadStatus = LoadStatusLargeResourceLoaded;
            currentIndex = LargeIndex;
            preferredIndex = LargeIndex;
        }
    }
};

/// This data structure stores the parameters for a low- and high-resolution texture.
struct AAPLTextureParams : public AAPLResourceCommon<id<MTLTexture>>
{
    /// Store the file headers for the high-resolution resources for streaming purposes.
    AAPLKTXTextureResource ktx[NumDetailLevels];
};

/// This data structure stores the parameters for a low- and high-resolution mesh.
struct AAPLModelParams : public AAPLResourceCommon<id<MTLBuffer>>
{
    /// Store the file headers for the high-resolution resources for streaming purposes.
    AAPLModelBufferFileHeader headers[NumDetailLevels];

    /// Store the vertex counts.
    size_t vertexCount[NumDetailLevels];
    /// Store the number of primitives to render.
    size_t indexCount[NumDetailLevels];
    
    /// Store the offsets into the MTLBuffer for the vertex buffer and index buffer.
    size_t positionsOffset[NumDetailLevels];
    size_t normalsOffset[NumDetailLevels];
    size_t texcoordsOffset[NumDetailLevels];
    size_t indexOffset[NumDetailLevels];
    
    /// Store the object transforms and shader parameters.
    AAPLObjectParams objectParams;
};

#pragma mark - Helper functions.

vector_float3 rampOffset(float t, vector_float3 offset)
{
    // Determine segment for the above curve.
    int seg = 0;
    if (t < 0.3333f)
    {
        seg = 0;
        t = t * 3;
    }
    else if (t >= 0.3333f && t < 0.66667f)
    {
        t = (t - 0.3333f) * 3;
        seg = 1;
    }
    else if (t >= 0.66667f && t <= 1.0f)
    {
        t = (t - 0.66667f) * 3;
        seg = 2;
    }
    
    if (seg == 0)
        t = t;
    if (seg == 1)
        t = 1.0f;
    if (seg == 2)
        t = 1.0f - t;
    
    // move t in the range 0 to 2PI.
    if (seg != 1)
    {
        t *= 3.141562653;
        t = 0.5 * sin(t - 3.1415926/2.0) + 0.5;
    }
    offset.x *= (1 - t);
    offset.y = 0;
    offset.z = -5 * t;

    return offset;
}

NSString* loadStatusToString(enum LoadStatus status)
{
    switch(status)
    {
        case LoadStatusSmallResourceLoaded: return @"Small";
        case LoadStatusLargeResourceLoading: return @"Loading";
        case LoadStatusLargeResourceLoaded: return @"Large";
    }
    return @"unknown";
}

#pragma mark - AAPLRenderer class.

@implementation AAPLRenderer
{
#if AAPL_ASYNCHRONOUS_RESOURCE_UPDATES
    /// Grand central dispatch for asynchronous updates.
    dispatch_queue_t _dispatch_queue;
#endif
    
    /// Metal resources for rendering the scene.
    id<MTLDevice>              _mtlDevice;
    MTKView*                   _mtkView;
    dispatch_semaphore_t       _inFlightSemaphore;
    id<MTLCommandQueue>        _commandQueue;
    id<MTLRenderPipelineState> _renderPSO;
    id<MTLDepthStencilState>   _depthStencilState;
    MTLRenderPassDescriptor*   _renderPassDescriptor;

    /// Metal resources and parameters for the sample animation.
    matrix_float4x4 _projectionMatrix;
    /// These are the view and projection transforms.
    matrix_float4x4 _viewMatrix;
    matrix_float4x4 _viewProjectionMatrix;
    
    float           _animationDegrees;
    float           _cycleDetailedObjectTime;
    
    /// This data structure holds all the headers and file sizes and offsets for the three models.
    AAPLModelParams _models[AAPLNumObjects];
    /// This data structure holds all the headers and file sizes and offsets for the three textures.
    AAPLTextureParams _textures[AAPLNumObjects];
    
#if AAPL_USE_MTLIO
    /// These Metal resources are for use with MTLIO.
    id<MTLIOCommandQueue> _ioQueue;
    std::atomic<size_t>   _pendingIOCommandsCount;
#endif
}

/// Create MTKView and load resources.
- (nonnull instancetype)initWithMetalKitView:(MTKView *)mtkView
{
    if(self = [super init])
    {
        _mtlDevice = mtkView.device;
        _mtkView = mtkView;
        
        [self loadMetal];
        [self loadResources];

#if AAPL_USE_MTLIO
        // Create the MTLIO command queue.
        MTLIOCommandQueueDescriptor* desc = [MTLIOCommandQueueDescriptor new];
        desc.type = MTLIOCommandQueueTypeConcurrent;
        desc.priority = MTLIOPriorityNormal;
        _ioQueue = [_mtlDevice newIOCommandQueueWithDescriptor:desc error:nil];
        assert(_ioQueue);
        _pendingIOCommandsCount = 0;
#endif

#if AAPL_ASYNCHRONOUS_RESOURCE_UPDATES
        _dispatch_queue = dispatch_queue_create("com.example.apple-samplecode.fast-resource-loading-queue", DISPATCH_QUEUE_SERIAL);
#endif

        // Set the label for the UI.
        _infoString = @"App initializing...";
    }
    return self;
}

/// Create Metal render state objects.
- (void)loadMetal
{
    NSError* error = nil;
    NSLog(@"Selected Device: %@", _mtlDevice.name);
    _mtkView.colorPixelFormat = MTLPixelFormatBGRA8Unorm_sRGB;
    _mtkView.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    _commandQueue = [_mtlDevice newCommandQueue];
    
    id<MTLLibrary> defaultLibrary = [_mtlDevice newDefaultLibrary];
    
    // Create the render pipeline to shade the geometry.
    {
        id<MTLFunction> vertexFunc   = [defaultLibrary newFunctionWithName:@"vertexShader"];
        id<MTLFunction> fragmentFunc = [defaultLibrary newFunctionWithName:@"fragmentShader"];
        
        MTLRenderPipelineDescriptor* renderPipelineDesc = [MTLRenderPipelineDescriptor new];
        renderPipelineDesc.vertexFunction = vertexFunc;
        renderPipelineDesc.fragmentFunction = fragmentFunc;
        renderPipelineDesc.vertexDescriptor = nil;
        renderPipelineDesc.colorAttachments[0].pixelFormat = _mtkView.colorPixelFormat;
        renderPipelineDesc.depthAttachmentPixelFormat = _mtkView.depthStencilPixelFormat;
        renderPipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormatInvalid;
        
        _renderPSO = [_mtlDevice newRenderPipelineStateWithDescriptor:renderPipelineDesc error:&error];
        NSAssert(_renderPSO, @"Failed to create forward plane with sparse texture render pipeline state");
    }
    
    // Create the default depth stencil state for the depth test.
    {
        MTLDepthStencilDescriptor* desc = [MTLDepthStencilDescriptor new];
        desc.depthWriteEnabled = YES;
        desc.depthCompareFunction = MTLCompareFunctionLess;
        _depthStencilState = [_mtlDevice newDepthStencilStateWithDescriptor:desc];
    }
    
    // Prefill the render pass descriptors with the clear, load, and store actions.
    {
        _renderPassDescriptor = [MTLRenderPassDescriptor new];
        _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.1, 1.0);
        _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        _renderPassDescriptor.depthAttachment.clearDepth = 1.0;
        _renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionClear;
        _renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    }
}

/// Configure the app, set initial values, and load the low- and high-resolution resource data.
- (void)loadResources
{
    _inFlightSemaphore    = dispatch_semaphore_create(AAPLMaxFramesInFlight);
    _animationDegrees        = 0.0f;
    _cycleDetailedObjectTime = 0.0f;
    _cycleDetailedObjects    = NO;
    _rotateObjects           = YES;
    
    for (size_t i = 0; i < AAPLNumObjects; i++)
    {
        // Read the file headers for low- and high-detail models.
        [self loadModelHeader:i resolutionIndex:SmallIndex];
        [self loadModelHeader:i resolutionIndex:LargeIndex];

        // Read the file headers for low- and high-resolution textures.
        [self loadTextureHeader:i resolutionIndex:SmallIndex];
        [self loadTextureHeader:i resolutionIndex:LargeIndex];

        // Load the low-detail meshes and low-resolution textures.
        [self loadModelData:i resolutionIndex:SmallIndex];
        [self loadTextureData:i resolutionIndex:SmallIndex];
    }
}

#pragma mark - Model and texture loading methods.

/// Load a 3D model from a file for the specified model and detail level.
- (void)loadModelHeader:(size_t)i resolutionIndex:(size_t)index
{
    NSString* resources[NumDetailLevels][AAPLNumObjects] = {
        {@"Assets/obj1-crazy-torus-lores.dat", @"Assets/obj2-menger-sponge-lores.dat", @"Assets/obj3-step-cylinder-lores.dat"},
        {@"Assets/obj1-crazy-torus-hires.dat", @"Assets/obj2-menger-sponge-hires.dat", @"Assets/obj3-step-cylinder-hires.dat"}
    };

    NSURL* url = [[NSBundle mainBundle] URLForResource:resources[index][i] withExtension:nil];
    assert(url);
    assert(index == SmallIndex || index == LargeIndex);
    _models[i].urls[index] = url;

    FILE* fin = fopen(url.path.UTF8String, "rb");
    fread((char*)&_models[i].headers[index], sizeof(AAPLModelBufferFileHeader), 1, fin);
    fclose(fin);
    
    _models[i].vertexCount[index] = _models[i].headers[index].vertexCount;
    _models[i].indexCount[index] = _models[i].headers[index].indexCount;
    _models[i].positionsOffset[index] = _models[i].headers[index].vertexPositionsOffset;
    _models[i].normalsOffset[index] = _models[i].headers[index].vertexNormalsOffset;
    _models[i].texcoordsOffset[index] = _models[i].headers[index].vertexTexcoordOffset;
    _models[i].indexOffset[index] = _models[i].headers[index].vertexSizeInBytes;
    _models[i].resources[index] = nil;
}

/// Load a texture using MTKTextureLoader.
- (void)loadTextureHeader:(size_t)i resolutionIndex:(size_t)index
{
    NSString* ktxTexturePaths[NumDetailLevels][AAPLNumObjects] = {
        {@"Assets/texture1-lores.ktx", @"Assets/texture2-lores.ktx", @"Assets/texture3-lores.ktx"},
        {@"Assets/texture1-hires.ktx", @"Assets/texture2-hires.ktx", @"Assets/texture3-hires.ktx"}};
    
    NSString* ktxPath = ktxTexturePaths[index][i];
    
    _textures[i].resources[index] = nil;
    _textures[i].urls[index] = [[NSBundle mainBundle] URLForResource:ktxPath withExtension:nil];
    _textures[i].ktx[index].readHeaderFromPath(_textures[i].urls[index].path.UTF8String);
}

#pragma mark - Traditional `fread` loading methods.

/// Load a 3D model data from a file for the specified model and resolution.
- (void)loadModelData:(size_t)i resolutionIndex:(size_t)index
{
    NSURL* sourceURL = _models[i].urls[index];
    FILE* fin = fopen(sourceURL.path.UTF8String, "rb");
    const size_t sourceOffset = _models[i].headers[index].vertexFileOffset;
    const size_t sizeInBytes = _models[i].headers[index].bufferSizeInBytes;
    id<MTLBuffer> buffer = [_mtlDevice newBufferWithLength:sizeInBytes options:MTLResourceStorageModeShared];
    buffer.label = sourceURL.lastPathComponent;
    
    fseek(fin, sourceOffset, SEEK_SET);
    fread((char*)buffer.contents, sizeInBytes, 1, fin);
    fclose(fin);
    
    // After loading the resource, make it available to use.
    _models[i].resources[index] = buffer;
}

/// Load a texture using fread.
- (void)loadTextureData:(size_t)i resolutionIndex:(size_t)index
{
    AAPLKTXTextureResource& ktx = _textures[i].ktx[index];
    
    // Assert a few requirements on the file format.
    assert(ktx.header.pixelDepth == 0);
    assert(ktx.header.numberOfArrayElements == 0);
    assert(ktx.header.numberOfFaces == 1);
    
    // Open the file to read and copy into MTLBuffer and MTLTexture.
    NSURL* sourceURL = _textures[i].urls[index];
    FILE* fin = fopen(sourceURL.path.UTF8String, "rb");
    assert(fin);
    
    // Allocate the texture for the KTX texture.
    MTLTextureDescriptor* desc = [MTLTextureDescriptor new];
    desc.width = ktx.header.pixelWidth;
    desc.height = ktx.header.pixelHeight;
    desc.mipmapLevelCount = ktx.mipmapCount;
    desc.pixelFormat = ktx.pixelFormat;
    
    id<MTLTexture> texture = [_mtlDevice newTextureWithDescriptor:desc];
    texture.label = sourceURL.lastPathComponent;
    
    // Open the command buffer to blit the file contents.
    auto commandBuffer = [_commandQueue commandBuffer];
    id<MTLBlitCommandEncoder> blitEncoder = [commandBuffer blitCommandEncoder];
    
    // Copy each mipmap level into a buffer and use the blit encoder to copy it to the texture.
    for (size_t level = 0; level < ktx.mipmapCount; level++)
    {
        // Create a temporary buffer and get a pointer to its contents.
        id<MTLBuffer> buffer = [_mtlDevice newBufferWithLength:ktx.mipmapBytesPerImage[level] options:MTLResourceStorageModeShared];
        char* bufferPtr = (char*)buffer.contents;
        
        // Advance the file position and read the mipmap data into the buffer.
        fseek(fin, ktx.mipmapFileOffsets[level], SEEK_SET);
        fread(bufferPtr, ktx.mipmapBytesPerImage[level], 1, fin);
        
        [blitEncoder copyFromBuffer:buffer
                       sourceOffset:0
                  sourceBytesPerRow:ktx.mipmapBytesPerRow[level]
                sourceBytesPerImage:ktx.mipmapBytesPerImage[level]
                         sourceSize:ktx.mipmapSizes[level]
                          toTexture:texture
                   destinationSlice:0
                   destinationLevel:level
                  destinationOrigin:MTLOriginMake(0, 0, 0)];
    }
    
    // After the reading the data, close the file.
    fclose(fin);
    
    // If mipmaps aren't in the file, generate them.
    if (!ktx.compressed && ktx.header.numberOfMipmapLevels == 1) {
        [blitEncoder generateMipmapsForTexture:texture];
    }
    
    // Submit GPU work.
    [blitEncoder endEncoding];
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    // After loading and blitting the texture, make it available to use.
    _textures[i].resources[index] = texture;
}

/// Process any requests to load high-resolution resources the "traditional" way.
- (void)loadResourcesUsingTraditionalLoaders
{
    // Start the loading process for the models and textures.
    for (int i = 0; i < AAPLNumObjects; i++) {
        if (_models[i].loadStatus == LoadStatusLargeResourceLoading) {
            [self loadModelData:i resolutionIndex:LargeIndex];
        }
        
        if (_textures[i].loadStatus == LoadStatusLargeResourceLoading) {
            [self loadTextureData:i resolutionIndex:LargeIndex];
        }
    }
    
    // Mark the high-resolution resources available for rendering.
    [self resourcesDidFinishLoading];
}

#pragma mark - MTLIO loading methods.

#if AAPL_USE_MTLIO

/// Encode the command to load the buffer resource with MTLIO.
- (void)loadModelDataWithMTLIO:(id<MTLIOCommandBuffer>)commandBuffer index:(size_t)i resolutionIndex:(size_t)index
{
    // Get the size and offset for this resource.
    size_t sizeInBytes = _models[i].headers[index].bufferSizeInBytes;
    size_t sourceOffset = _models[i].headers[index].vertexFileOffset;
    NSURL* sourceURL = _models[i].urls[index];
    
    // Get a handle to this resource.
    if (!_models[i].handles[index])
    {
        NSError* error;
        id<MTLIOFileHandle> handle = [_mtlDevice newIOHandleWithURL:sourceURL error:&error];
        if (!handle)
        {
            NSString* reason = [NSString stringWithFormat:@"Error loading resource (%@) : %@", sourceURL.lastPathComponent, error];
            NSException* exc = [NSException exceptionWithName:@"Texture loading exception" reason:reason userInfo:nil];
            @throw exc;
        }
        _models[i].handles[index] = handle;
    }
    
    // Allocate a new buffer and add it to the command queue.
    id<MTLBuffer> buffer = [_mtlDevice newBufferWithLength:sizeInBytes options:MTLResourceStorageModeShared];
    buffer.label = sourceURL.lastPathComponent;
    [commandBuffer loadBuffer:buffer
                       offset:0
                         size:sizeInBytes
                 sourceHandle:_models[i].handles[index]
           sourceHandleOffset:sourceOffset];
    
    // After loading the resource, make it available to use.
    _models[i].resources[index] = buffer;
}

/// Encode the command to load the texture resource and its mipmaps with MTLIO.
- (void)loadTextureDataWithMTLIO:(id<MTLIOCommandBuffer>)commandBuffer index:(size_t)i resolutionIndex:(size_t)index
{
    auto& ktx = _textures[i].ktx[index];
    
    // Get the size and offset for this resource.
    NSURL* sourceURL = _textures[i].urls[index];
    
    // Get a handle to this resource.
    if (!_textures[i].handles[index])
    {
        NSError* error;
        id<MTLIOFileHandle> handle = [_mtlDevice newIOHandleWithURL:sourceURL error:&error];
        if (!handle)
        {
            NSString* reason = [NSString stringWithFormat:@"Error loading resource (%@) : %@", sourceURL.lastPathComponent, error];
            NSException* exc = [NSException exceptionWithName:@"Texture loading exception" reason:reason userInfo:nil];
            @throw exc;
        }
        _textures[i].handles[index] = handle;
    }
    
    // Allocate a new buffer and add it to the command queue.
    MTLTextureDescriptor* desc = [MTLTextureDescriptor new];
    desc.width = ktx.header.pixelWidth;
    desc.height = ktx.header.pixelHeight;
    desc.pixelFormat = ktx.pixelFormat;
    desc.mipmapLevelCount = ktx.mipmapCount;
    desc.storageMode = MTLStorageModePrivate;
    
    // Encode the command to load the texture mipmap level.
    id<MTLTexture> texture = [_mtlDevice newTextureWithDescriptor:desc];
    texture.label = sourceURL.lastPathComponent;
    for (int level = 0; level < ktx.mipmapCount; level++)
    {
        [commandBuffer loadTexture:texture
                             slice:0
                             level:level
                              size:ktx.mipmapSizes[level]
                 sourceBytesPerRow:ktx.mipmapBytesPerRow[level]
               sourceBytesPerImage:ktx.mipmapSizesInBytes[level]
                 destinationOrigin:MTLOriginMake(0, 0, 0)
                      sourceHandle:_textures[i].handles[index]
                sourceHandleOffset:ktx.mipmapFileOffsets[level]];
    }
    
    // After loading the texture, make it available to use.
    _textures[i].resources[index] = texture;
}

/// Process any requests to load high-resolution resources with fast resource loading.
- (void)loadResourcesUsingMTLIO
{
    // If there are too many pending IO commands, return without doing anything.
    if (_pendingIOCommandsCount.load() > 8)
        return;

    // Create the MTLIO command buffer and increment the number of pending commands.
    id<MTLIOCommandBuffer> commandBuffer = [_ioQueue commandBuffer];
    _pendingIOCommandsCount.fetch_add(1);
    
    for (int i = 0; i < AAPLNumObjects; i++)
    {
        // Process the 3D model buffers.
        if (_models[i].loadStatus == LoadStatusLargeResourceLoading)
            [self loadModelDataWithMTLIO:commandBuffer index:i resolutionIndex:LargeIndex];

        // Process the 2D texture maps.
        if (_textures[i].loadStatus == LoadStatusLargeResourceLoading)
            [self loadTextureDataWithMTLIO:commandBuffer index:i resolutionIndex:LargeIndex];
    }
    
    // Commit the command buffer and wait for resources to load.
    [commandBuffer addCompletedHandler:^(id<MTLIOCommandBuffer> nonnull) {
        if (commandBuffer.status == MTLIOStatusComplete)
            [self resourcesDidFinishLoading];
        self->_pendingIOCommandsCount.fetch_sub(1);
    }];
    [commandBuffer commit];
}
#endif // AAPL_USE_MTLIO

#pragma mark - Low- and high-resolution update methods.

/// Unloads high-resolution assets that are no longer needed and requests high-resolution resources to load.
- (size_t)unloadAndStageResources
{
    // Unload unnecessary high-resolution models.
    for (int i = 0; i < AAPLNumObjects; i++)
    {
        // Unload a model that the "Reload" UI button triggers.
        if (_reloadDetailedObject)
        {
            _models[i].preferredIndex = SmallIndex;
            _textures[i].preferredIndex = SmallIndex;
        }
        
        // Unload the model buffers and textures.
        _models[i].unload();
        _textures[i].unload();
    }
    
    // Clear the reload UI button flag.
    _reloadDetailedObject = false;
    
    // Stage the models that require a high-resolution model or texture.
    // Count them so the loading function encodes and processes the work.
    size_t resourcesToLoadCount = 0;
    for (int i = 0; i < AAPLNumObjects; i++)
    {
        resourcesToLoadCount += _models[i].stage();
        resourcesToLoadCount += _textures[i].stage();
    }
    return resourcesToLoadCount;
}

/// The loadResources... functions call this method to make the models and textures available.
- (void)resourcesDidFinishLoading
{
    for (int i = 0; i < AAPLNumObjects; i++)
    {
        _models[i].setLoaded();
        _textures[i].setLoaded();
    }
}

#pragma mark - Update, render and resize methods.

/// Update the app state and the constant buffers for the shaders.
- (void)updateAnimationAndBuffers
{
    // Update the animation parameters.
    if(_cycleDetailedObjects)
    {
        _cycleDetailedObjectTime += 0.00125;
    }
    
    if (_rotateObjects)
    {
        _animationDegrees += .001;
    }
    
    // Process the animation and choice of low- and high-detail resources.
    for (int i = 0; i < AAPLNumObjects; i++)
    {
        // Center the objects horizontally.
        vector_float3 offset = (vector_float3){0,0,0};
        offset.x = 4.0f * (i - (float(AAPLNumObjects - 1) / 2));
        
        // Use the floating-point remainder of the cycle time and the number of objects.
        float t = fmod(_cycleDetailedObjectTime, AAPLNumObjects);
        if (t < i || t >= i+1)
        {
            _models[i].preferredIndex = SmallIndex;
            _textures[i].preferredIndex = SmallIndex;
        }
        else
        {
            // The shape of the offset looks like a smooth ramp.
            // It ramps up over a few seconds, holds for a few seconds, and then ramps down over a few seconds.
            //      _______
            //     /       \
            // .../         \...
            
            // Move t in the range 0 to 1.
            t -= i;
            offset = rampOffset(t, offset);
            
            // If animation isn't started, don't prefer the high-detail resource.
            // The app also switches back to the low-resolution version just before the mesh starts its return.
            if (_cycleDetailedObjectTime == 0 || t > 0.6)
            {
                _models[i].preferredIndex = SmallIndex;
                _textures[i].preferredIndex = SmallIndex;
            }
            else
            {
                _models[i].preferredIndex = LargeIndex;
                _textures[i].preferredIndex = LargeIndex;
            }
        }
        
        // Update the view and projection matrices.
        _viewMatrix = matrix4x4_translation(0, 0, 8);
        _viewProjectionMatrix = matrix_multiply(_projectionMatrix, _viewMatrix);

        // Calculate the transformation matrices for this model.
        matrix_float4x4 T = matrix4x4_translation(offset);
        matrix_float4x4 azimuth = matrix4x4_rotation(_animationDegrees, 0, 1, 0);
        matrix_float4x4 tilt = matrix4x4_rotation(-0.3f, 1, 0, 0);
        matrix_float4x4 R = matrix_multiply(tilt, azimuth);
        matrix_float4x4 M = matrix_multiply(T, R);
        _models[i].objectParams.modelMatrix = M;
        _models[i].objectParams.modelViewProjectionMatrix = matrix_multiply(_viewProjectionMatrix, M);
        _models[i].objectParams.normalMatrix = matrix3x3_upper_left(M);
    }
}

/// Draw the scene with the low- and high-detail models.
- (void)drawSceneWithCommandBuffer:(id<MTLCommandBuffer>)commandBuffer
{
    _renderPassDescriptor.colorAttachments[0].texture = _mtkView.currentDrawable.texture;
    _renderPassDescriptor.depthAttachment.texture = _mtkView.depthStencilTexture;
    _renderPassDescriptor.depthAttachment.storeAction = MTLStoreActionDontCare;
    
    // Open the command encoder and set the common drawing parameters.
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    [renderEncoder setCullMode:MTLCullModeBack];
    [renderEncoder setFrontFacingWinding:MTLWindingClockwise];
    [renderEncoder setDepthStencilState:_depthStencilState];
    [renderEncoder setRenderPipelineState:_renderPSO];
    
    // Encode each mesh.
    for (int i = 0; i < AAPLNumObjects; i++)
    {
        size_t modelIndex = _models[i].currentIndex;
        size_t textureIndex = _textures[i].currentIndex;
        id<MTLBuffer> buffer = _models[i].resources[modelIndex];
        id<MTLTexture> texture = _textures[i].resources[textureIndex];
        [renderEncoder setVertexBuffer:buffer offset:_models[i].positionsOffset[modelIndex] atIndex:AAPLBufferIndexPositions];
        [renderEncoder setVertexBuffer:buffer offset:_models[i].normalsOffset[modelIndex] atIndex:AAPLBufferIndexNormals];
        [renderEncoder setVertexBuffer:buffer offset:_models[i].texcoordsOffset[modelIndex] atIndex:AAPLBufferIndexTexcoords];
        [renderEncoder setVertexBytes:&_models[i].objectParams length:sizeof(AAPLObjectParams) atIndex:AAPLBufferIndexObjectParams];
        [renderEncoder setFragmentTexture:texture atIndex:0];
        [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                  indexCount:_models[i].indexCount[modelIndex]
                                   indexType:MTLIndexTypeUInt32
                                 indexBuffer:buffer
                           indexBufferOffset:_models[i].indexOffset[modelIndex]];
    }
    [renderEncoder endEncoding];
}

/// Load high-resolution resources as necessary.
- (void)updateHighResolutionResources
{
    // Load and unload high-resolution resources using fast resource loading or the traditional way.
    size_t loadCount = [self unloadAndStageResources];
    if (loadCount > 0)
    {
#if AAPL_USE_MTLIO
        if (self.useMTLIO)
            [self loadResourcesUsingMTLIO];
        else
            [self loadResourcesUsingTraditionalLoaders];
#else
        [self loadResourcesUsingTraditionalLoaders];
#endif
    }
    
    // Determine the total size of the resources that the buffers and textures use.
    double allocatedSizeInMiB = 0;
    for (int i = 0; i < AAPLNumObjects; i++) {
        for (int j = 0; j < NumDetailLevels; j++) {
            if (_models[i].resources[j])
                allocatedSizeInMiB += _models[i].resources[j].allocatedSize;
            if (_textures[i].resources[j])
                allocatedSizeInMiB += _textures[i].resources[j].allocatedSize;
        }
    }
    allocatedSizeInMiB /= 1048576.0;
    
    // Update the info string for the user interface.
    _infoString = [[NSString alloc] initWithFormat:@"Object 1: %@|%@  Object 2: %@|%@  Object3: %@|%@  Memory: %3.2f MiB",
                   loadStatusToString(_models[0].loadStatus), loadStatusToString(_textures[0].loadStatus),
                   loadStatusToString(_models[1].loadStatus), loadStatusToString(_textures[1].loadStatus),
                   loadStatusToString(_models[2].loadStatus), loadStatusToString(_textures[2].loadStatus),
                   allocatedSizeInMiB
    ];
}

/// MTKViewDelegate Callback: Draw the scene into the view.
- (void)drawInMTKView:(nonnull MTKView*) view
{
    // Wait for a free command queue, and then prepare the command buffer for rendering.
    dispatch_semaphore_wait(_inFlightSemaphore, DISPATCH_TIME_FOREVER);
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Main render cmd buffer";
    
    // Update the animation and constant data buffers for the sample.
    [self updateAnimationAndBuffers];
    
    // Begin the forward render pass.
    [self drawSceneWithCommandBuffer:commandBuffer];
    
    // Submit the command buffer for rendering.
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> _Nonnull cmdBuffer)
    {
        dispatch_semaphore_signal(self->_inFlightSemaphore);
    }];
    [commandBuffer presentDrawable:_mtkView.currentDrawable];
    [commandBuffer commit];

#if AAPL_ASYNCHRONOUS_RESOURCE_UPDATES
    dispatch_async(_dispatch_queue, ^{
        [self updateHighResolutionResources];
    });
#else
    [self updateHighResolutionResources];
#endif
}

/// MTKViewDelegate Callback: Respond to the device orientation change or other view size change.
- (void)mtkView:(nonnull MTKView*) view drawableSizeWillChange:(CGSize)size
{
    float aspect = (float)size.width / (float)size.height;
    _projectionMatrix = matrix_perspective_left_hand(radians_from_degrees(60.0f), aspect, 1.f, 100.0f);
}

@end
