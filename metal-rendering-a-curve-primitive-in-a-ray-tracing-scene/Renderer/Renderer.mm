/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

#import <simd/simd.h>

#import "Renderer.h"
#import "Geometry.h"
#import "MathUtilities.h"
#import "ShaderTypes.h"

using namespace simd;

static const NSUInteger maxFramesInFlight = 3;
static const size_t alignedUniformsSize = (sizeof(Uniforms) + 255) & ~255;

@implementation Renderer
{
    id <MTLDevice> _device;
    id <MTLCommandQueue> _queue;
    id <MTLLibrary> _library;
    
    id <MTLBuffer> _uniformBuffer;
    
    id <MTLAccelerationStructure> _instanceAccelerationStructure;
    NSMutableArray *_primitiveAccelerationStructures;
    
    id <MTLComputePipelineState> _raytracingPipeline;
    id <MTLRenderPipelineState> _copyPipeline;
    
    id <MTLTexture> _accumulationTargets[2];
    id <MTLTexture> _randomTexture;
    
    id <MTLBuffer> _instanceBuffer;
    
    id <MTLIntersectionFunctionTable> _intersectionFunctionTable;
    
    dispatch_semaphore_t _sem;
    CGSize _size;
    NSUInteger _uniformBufferOffset;
    NSUInteger _uniformBufferIndex;
    
    unsigned int _frameIndex;
    
    id <MTLBuffer> _controlPointBuffer;
    id <MTLBuffer> _curveIndexBuffer;
    id <MTLBuffer> _vertexNormalBuffer;
    id <MTLBuffer> _vertexIndexBuffer;
    id <MTLBuffer> _transform;
}

// Set up Metal, and create buffers, acceleration structures, and the rendering pipeline.
- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
{
    self = [super init];
    
    if (self)
    {
        _device = device;
        
        _sem = dispatch_semaphore_create(maxFramesInFlight);
        
        [self loadMetal];
        [self createBuffers];
        [self createAccelerationStructures];
        [self createPipelines];
    }
    
    return self;
}

// Initialize the Metal shader library and command queue.
- (void)loadMetal
{
    _library = [_device newDefaultLibrary];
    
    _queue = [_device newCommandQueue];
}

// Create a compute pipeline state with an optional array of additional functions to link the compute
// function with. The sample uses this to link the ray-tracing kernel with any intersection functions.
- (id <MTLComputePipelineState>)newComputePipelineStateWithFunction:(id <MTLFunction>)function
                                                    linkedFunctions:(NSArray <id <MTLFunction>> *)linkedFunctions
{
    MTLLinkedFunctions *mtlLinkedFunctions = nil;
    
    // Attach the additional functions to an MTLLinkedFunctions object.
    if (linkedFunctions) {
        mtlLinkedFunctions = [[MTLLinkedFunctions alloc] init];
        
        mtlLinkedFunctions.functions = linkedFunctions;
    }
    
    MTLComputePipelineDescriptor *descriptor = [[MTLComputePipelineDescriptor alloc] init];
    
    // Set the main compute function.
    descriptor.computeFunction = function;
    
    // Attach the linked functions object to the compute pipeline descriptor.
    descriptor.linkedFunctions = mtlLinkedFunctions;
    
    // Set this to YES to allow the compiler to make certain optimizations.
    descriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;
    
    NSError *error;
    
    // Create the compute pipeline state.
    id <MTLComputePipelineState> pipeline = [_device newComputePipelineStateWithDescriptor:descriptor
                                                                                   options:0
                                                                                reflection:nil
                                                                                     error:&error];
    NSAssert(pipeline, @"Failed to create %@ pipeline state: %@", function.name, error);
    
    return pipeline;
}

// Create pipeline states.
- (void)createPipelines
{
    // Map the intersection function name to the actual MTLFunction.
    NSMutableDictionary <NSString *, id <MTLFunction>> *intersectionFunctions = [NSMutableDictionary dictionary];
    std::vector<NSString*> intersectionFunctionsNames = {@"triangleIntersectionFunction", @"catmullRomCurveIntersectionFunction"};
    for (int i = 0; i < intersectionFunctionsNames.size(); i++)
    {
        id <MTLFunction> intersectionFunction = [_library newFunctionWithName:intersectionFunctionsNames[i]];
        // Map the ray-tracing function name to the actual MTLFunction.
        intersectionFunctions[intersectionFunctionsNames[i]] = intersectionFunction;
    }
    id <MTLFunction> raytracingFunction = [_library newFunctionWithName:@"raytracingKernel"];
    
    // Create the compute pipeline state, which does all the ray tracing.
    _raytracingPipeline = [self newComputePipelineStateWithFunction:raytracingFunction
                                                    linkedFunctions:[intersectionFunctions allValues]];
    
    // Create the intersection function table.
    MTLIntersectionFunctionTableDescriptor *intersectionFunctionTableDescriptor = [[MTLIntersectionFunctionTableDescriptor alloc] init];
    intersectionFunctionTableDescriptor.functionCount = intersectionFunctionsNames.size();
    
    // Create a table large enough to hold all of the intersection functions. Metal
    // links intersection functions into the compute pipeline state, potentially with
    // a different address for each compute pipeline. Therefore, the intersection
    // function table is specific to the compute pipeline state that creates it, and you
    // can use it with only that pipeline.
    _intersectionFunctionTable = [_raytracingPipeline newIntersectionFunctionTableWithDescriptor:intersectionFunctionTableDescriptor];
    
    // Set up a custom intersection function.
    for (int i = 0; i < intersectionFunctionsNames.size(); i++)
    {
        id <MTLFunction> intersectionFunction = intersectionFunctions[intersectionFunctionsNames[i]];
        id <MTLFunctionHandle> handle = [_raytracingPipeline functionHandleWithFunction:intersectionFunction];
        [_intersectionFunctionTable setFunction:handle atIndex:i];
    }
    
    // Bind custom resources to the intersection function table.
    [_intersectionFunctionTable setBuffer:_controlPointBuffer offset:0 atIndex:0];
    [_intersectionFunctionTable setBuffer:_curveIndexBuffer offset:0 atIndex:1];
    [_intersectionFunctionTable setBuffer:_vertexNormalBuffer offset:0 atIndex:2];
    [_intersectionFunctionTable setBuffer:_vertexIndexBuffer offset:0 atIndex:3];
    
    // Create a render pipeline state that copies the rendered scene into the MTKView and
    // performs simple tone mapping.
    MTLRenderPipelineDescriptor *renderDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    
    renderDescriptor.vertexFunction = [_library newFunctionWithName:@"copyVertex"];
    renderDescriptor.fragmentFunction = [_library newFunctionWithName:@"copyFragment"];
    
    renderDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
    
    NSError *error;
    
    _copyPipeline = [_device newRenderPipelineStateWithDescriptor:renderDescriptor error:&error];
    
    NSAssert(_copyPipeline, @"Failed to create the copy pipeline state %@: %@", raytracingFunction.name, error);
}

- (MTLResourceOptions) getManagedBufferStorageMode {
#if !TARGET_OS_IPHONE
    if ([_device hasUnifiedMemory])
        return MTLResourceStorageModeShared;
    else
        return MTLResourceStorageModeManaged;
#else
    return MTLResourceStorageModeShared;
#endif
}

- (void)createBuffers {
    // The uniform buffer contains a few small values, which change from frame to frame. The
    // sample can have up to three frames in flight at the same time, so allocate a range of the buffer
    // for each frame. The GPU reads from one chunk while the CPU writes to the next chunk.
    // Align the chunks to 256 bytes in macOS and 16 bytes in iOS.
    NSUInteger uniformBufferSize = alignedUniformsSize * maxFramesInFlight;
    
    MTLResourceOptions options = [self getManagedBufferStorageMode];
    
    _uniformBuffer = [_device newBufferWithLength:uniformBufferSize options:options];
}

// Create and compact an acceleration structure, given an acceleration structure descriptor.
- (id <MTLAccelerationStructure>)newAccelerationStructureWithDescriptor:(MTLAccelerationStructureDescriptor *)descriptor
{
    // Query for the sizes needed to store and build the acceleration structure.
    MTLAccelerationStructureSizes accelSizes = [_device accelerationStructureSizesWithDescriptor:descriptor];
    
    // Allocate an acceleration structure large enough for this descriptor. This method
    // doesn't actually build the acceleration structure, but rather allocates memory.
    id <MTLAccelerationStructure> accelerationStructure = [_device newAccelerationStructureWithSize:accelSizes.accelerationStructureSize];
    
    // Allocate scratch space Metal uses to build the acceleration structure.
    // Use MTLResourceStorageModePrivate for the best performance because the sample
    // doesn't need access to the buffer's contents.
    id <MTLBuffer> scratchBuffer = [_device newBufferWithLength:accelSizes.buildScratchBufferSize options:MTLResourceStorageModePrivate];
    
    // Create a command buffer that performs the acceleration structure build.
    id <MTLCommandBuffer> commandBuffer = [_queue commandBuffer];
    
    // Create an acceleration structure command encoder.
    id <MTLAccelerationStructureCommandEncoder> commandEncoder = [commandBuffer accelerationStructureCommandEncoder];
    
    // Allocate a buffer for Metal to write the compacted accelerated structure's size into.
    id <MTLBuffer> compactedSizeBuffer = [_device newBufferWithLength:sizeof(uint32_t) options:MTLResourceStorageModeShared];
    
    // Schedule the actual acceleration structure build.
    [commandEncoder buildAccelerationStructure:accelerationStructure
                                    descriptor:descriptor
                                 scratchBuffer:scratchBuffer
                           scratchBufferOffset:0];
    
    // Compute and write the compacted acceleration structure size into the buffer. You
    // need to already have a built acceleration structure because Metal determines the compacted
    // size based on the final size of the acceleration structure. Compacting an acceleration
    // structure can potentially reclaim significant amounts of memory because Metal needs to
    // create the initial structure using a conservative approach.
    
    [commandEncoder writeCompactedAccelerationStructureSize:accelerationStructure
                                                   toBuffer:compactedSizeBuffer
                                                     offset:0];
    
    // End encoding, and commit the command buffer so the GPU can start building the
    // acceleration structure.
    [commandEncoder endEncoding];
    
    [commandBuffer commit];
    
    // The sample waits for Metal to finish executing the command buffer so that it can
    // read back the compacted size.
    
    // Note: Don't wait for Metal to finish executing the command buffer if you aren't compacting
    // the acceleration structure because doing so requires CPU/GPU synchronization. You don't have
    // to compact acceleration structures, but do so when creating large static acceleration
    // structures, such as static scene geometry. Avoid compacting acceleration structures that
    // you rebuild every frame because the synchronization cost may be significant.
    
    [commandBuffer waitUntilCompleted];
    
    uint32_t compactedSize = *(uint32_t *)compactedSizeBuffer.contents;
    
    // Allocate a smaller acceleration structure based on the returned size.
    id <MTLAccelerationStructure> compactedAccelerationStructure = [_device newAccelerationStructureWithSize:compactedSize];
    
    // Create another command buffer and encoder.
    commandBuffer = [_queue commandBuffer];
    
    commandEncoder = [commandBuffer accelerationStructureCommandEncoder];
    
    // Encode the command to copy and compact the acceleration structure into the
    // smaller acceleration structure.
    [commandEncoder copyAndCompactAccelerationStructure:accelerationStructure
                                toAccelerationStructure:compactedAccelerationStructure];
    
    // End encoding and commit the command buffer. You don't need to wait for Metal to finish
    // executing this command buffer as long as you synchronize any ray-intersection work
    // to run after this command buffer completes. The sample relies on Metal's default
    // dependency tracking on resources to automatically synchronize access to the new
    // compacted acceleration structure.
    [commandEncoder endEncoding];
    [commandBuffer commit];
    
    return compactedAccelerationStructure;
}

// Create acceleration structures for the scene. The scene contains primitive acceleration
// structures and an instance acceleration structure. The primitive acceleration structures
// contain primitives, such as triangles and curves. The instance acceleration structure contains
// copies, or instances, of the primitive acceleration structures, each with their own
// transformation matrix that describes where to place them in the scene.
- (void)createAccelerationStructures
{
    MTLResourceOptions options = [self getManagedBufferStorageMode];
    
    // Create an array of primitive acceleration structures.
    _primitiveAccelerationStructures = [[NSMutableArray alloc] init];
    
    NSUInteger geometryCount = 2;
    
    // Create a plane object.
    std::vector<::simd_float3> planeVertices = {
        vector3(-4.5f, -1.1f,  0.0f),
        vector3(-4.5f, -1.1f,  5.0f),
        vector3( 4.5f, -1.1f,  5.0f),
        vector3( 4.5f, -1.1f,  0.0f)
    };
    PlaneGeometry *plane = [[PlaneGeometry alloc] initWithDevice:_device];
    MTLPrimitiveAccelerationStructureDescriptor *planeAccelDesc = [plane addPlane:planeVertices];
    // Build the acceleration structure.
    id <MTLAccelerationStructure> planeAccelerationStructure = [self newAccelerationStructureWithDescriptor:planeAccelDesc];
    // Add the acceleration structure to the array of primitive acceleration structures.
    [_primitiveAccelerationStructures addObject:planeAccelerationStructure];
    
    // Define the Catmull-Rom spiral curve's control points, indices, and radii.
    // Each control point helps to define the shape of a curve and has a 3D position and radius.
    std::vector<::simd_float3> catmullControlPoints;
    size_t controlPointCount = 45;
    for (int i = 0; i < controlPointCount; i++)
    {
        float x = cos(i * M_PI / 5) * (1 - 0.01 * i);
        float y = i * 0.02f;
        float z = sin(i * M_PI / 5) * (1 - 0.01 * i);
        catmullControlPoints.push_back(vector3(x, y, z));
    }
    std::vector<uint16_t> catmullIndices;
    size_t indicesPerSegment = 4;
    size_t indexCount = controlPointCount - (indicesPerSegment + 1);
    for (uint16_t idx = 0; idx < indexCount; idx++)
    {
        catmullIndices.push_back(idx);
    }
    std::vector<float> radii;
    float radius = 0.015f;
    for(uint64_t i = 0; i < controlPointCount; ++i)
    {
        radii.push_back(radius);
    }
    
    // Create a Catmull-Rom curve object.
    CurveGeometry *catmullCurveGeometry = [[CurveGeometry alloc] initWithDevice:_device];
    MTLPrimitiveAccelerationStructureDescriptor *catmullCurveAccelDesc = [catmullCurveGeometry addCurveWithControlPoints:catmullControlPoints curveIndices:catmullIndices radii:radii];
    // Build the acceleration structure.
    id <MTLAccelerationStructure> catmullCurveAccelerationStructure = [self newAccelerationStructureWithDescriptor:catmullCurveAccelDesc];
    // Add the acceleration structure to the array of primitive acceleration structures.
    [_primitiveAccelerationStructures addObject:catmullCurveAccelerationStructure];
    
    _controlPointBuffer = catmullCurveGeometry.controlPointBuffer;
    _curveIndexBuffer = catmullCurveGeometry.curveIndexBuffer;
    _vertexNormalBuffer = plane.vertexNormalBuffer;
    _vertexIndexBuffer = plane.vertexIndexBuffer;
    
    // Allocate a buffer of acceleration structure instance descriptors. Each descriptor represents
    // an instance of one of the primitive acceleration structures created above, with its own
    // transformation matrix.
    _instanceBuffer = [_device newBufferWithLength:sizeof(MTLAccelerationStructureInstanceDescriptor) * geometryCount options:options];
    
    MTLAccelerationStructureInstanceDescriptor *instanceDescriptors = (MTLAccelerationStructureInstanceDescriptor *)_instanceBuffer.contents;
    
    // Fill out the instance descriptors.
    NSUInteger geometryIndex = 0;
    std::vector<matrix_float4x4> transformMatrices;
    transformMatrices.push_back(matrix4x4_translation(0.0f, 1.0f, 0.0f));
    transformMatrices.push_back(matrix4x4_translation(0.0f, 0.0f, 0.0f));
    uint32_t mask = (uint32_t)0xFF;;
    for (int i = 0; i < geometryCount; i++)
    {
        instanceDescriptors[i].accelerationStructureIndex = (uint32_t)geometryIndex + i;
        instanceDescriptors[i].options = MTLAccelerationStructureInstanceOptionNone;
        instanceDescriptors[i].intersectionFunctionTableOffset = 0;
        instanceDescriptors[i].mask = mask;
        for (int column = 0; column < 4; column++)
        {
            for (int row = 0; row < 3; row++)
            {
                instanceDescriptors[i].transformationMatrix.columns[column][row] = transformMatrices[i].columns[column][row];
            }
        }
    }
    
    // Save the transform matrices to bind to the intersection function table.
    _transform = [_device newBufferWithLength:2 * sizeof(matrix_float4x4) options:options];
    memcpy(_transform.contents, transformMatrices.data(), _transform.length);
#if !TARGET_OS_IPHONE
    if (![_device hasUnifiedMemory])
    {
        [_transform didModifyRange:NSMakeRange(0, _transform.length)];
        [_instanceBuffer didModifyRange:NSMakeRange(0, _instanceBuffer.length)];
    }
#endif
    // Create an instance acceleration structure descriptor.
    MTLInstanceAccelerationStructureDescriptor *instanceAccelDescriptor = [MTLInstanceAccelerationStructureDescriptor descriptor];
    
    instanceAccelDescriptor.instancedAccelerationStructures = _primitiveAccelerationStructures;
    instanceAccelDescriptor.instanceCount = geometryCount;
    instanceAccelDescriptor.instanceDescriptorBuffer = _instanceBuffer;
    
    // Create the instance acceleration structure that contains all instances in the scene.
    _instanceAccelerationStructure = [self newAccelerationStructureWithDescriptor:instanceAccelDescriptor];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _size = size;
    
    // Create a pair of textures that the ray-tracing kernel uses to accumulate
    // samples over several frames.
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];
    
    textureDescriptor.pixelFormat = MTLPixelFormatRGBA32Float;
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.width = size.width;
    textureDescriptor.height = size.height;
    
    // Store the texture in private memory because only the GPU reads or writes this texture.
    textureDescriptor.storageMode = MTLStorageModePrivate;
    textureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;
    
    for (NSUInteger i = 0; i < 2; i++)
        _accumulationTargets[i] = [_device newTextureWithDescriptor:textureDescriptor];
    
    // Create a texture that contains a random integer value for each pixel. The sample
    // uses these values to decorrelate pixels while drawing pseudorandom numbers from the
    // Halton sequence.
    textureDescriptor.pixelFormat = MTLPixelFormatR32Uint;
    textureDescriptor.usage = MTLTextureUsageShaderRead;
    
    // The sample initializes the data in the texture, so it can't be private.
#if !TARGET_OS_IPHONE
    if ([_device supportsFamily:MTLGPUFamilyApple7])
        textureDescriptor.storageMode = MTLStorageModeShared;
    else
        textureDescriptor.storageMode = MTLStorageModeManaged;
#else
    textureDescriptor.storageMode = MTLStorageModeShared;
#endif
    
    _randomTexture = [_device newTextureWithDescriptor:textureDescriptor];
    
    // Initialize the random values.
    uint32_t *randomValues = (uint32_t *)malloc(sizeof(uint32_t) * size.width * size.height);
    
    for (NSUInteger i = 0; i < size.width * size.height; i++)
        randomValues[i] = rand() % (1024 * 1024);
    
    [_randomTexture replaceRegion:MTLRegionMake2D(0, 0, size.width, size.height)
                      mipmapLevel:0
                        withBytes:randomValues
                      bytesPerRow:sizeof(uint32_t) * size.width];
    
    free(randomValues);
    
    _frameIndex = 0;
}

- (void)updateUniforms {
    _uniformBufferOffset = alignedUniformsSize * _uniformBufferIndex;
    
    Uniforms *uniforms = (Uniforms *)((char *)_uniformBuffer.contents + _uniformBufferOffset);
    
    vector_float3 position = vector3(0.0f, 1.0f, 2.5f);
    vector_float3 target = vector3(0.0f, 0.0f, 0.0f);
    vector_float3 up = vector3(0.0f, 1.0f, 0.0f);
    
    vector_float3 forward = vector_normalize(target - position);
    vector_float3 right = vector_normalize(vector_cross(forward, up));
    up = vector_normalize(vector_cross(right, forward));
    
    uniforms->camera.position = position;
    uniforms->camera.forward = forward;
    uniforms->camera.right = right;
    uniforms->camera.up = up;
    
    float fieldOfView = 45.0f * (M_PI / 180.0f);
    float aspectRatio = (float)_size.width / (float)_size.height;
    float imagePlaneHeight = tanf(fieldOfView / 2.0f);
    float imagePlaneWidth = aspectRatio * imagePlaneHeight;
    
    uniforms->camera.right *= imagePlaneWidth;
    uniforms->camera.up *= imagePlaneHeight;
    
    uniforms->width = (unsigned int)_size.width;
    uniforms->height = (unsigned int)_size.height;
    
    uniforms->frameIndex = _frameIndex++;
    
#if !TARGET_OS_IPHONE
    if (![_device hasUnifiedMemory])
    {
        [_uniformBuffer didModifyRange:NSMakeRange(_uniformBufferOffset, alignedUniformsSize)];
    }
#endif
    
    // Advance to the next slot in the uniform buffer.
    _uniformBufferIndex = (_uniformBufferIndex + 1) % maxFramesInFlight;
}

- (void)drawInMTKView:(MTKView *)view {
    // The sample uses the uniform buffer to stream uniform data to the GPU, so it
    // needs to wait until the GPU finishes processing the oldest GPU frame before
    // it can reuse that space in the buffer.
    dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);
    
    // Create a command for the frame's commands.
    id <MTLCommandBuffer> commandBuffer = [_queue commandBuffer];
    
    __block dispatch_semaphore_t sem = _sem;
    
    // When the GPU finishes processing the command buffer for the frame, signal
    // the semaphore to make the space in the uniform buffer available for future frames.
    
    // Note: Completion handlers need to be as fast as possible because the GPU
    // driver may have other work scheduled on the underlying dispatch queue.
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(sem);
    }];
    
    [self updateUniforms];
    
    NSUInteger width = (NSUInteger)_size.width;
    NSUInteger height = (NSUInteger)_size.height;
    
    // Launch a rectangular grid of threads on the GPU to perform ray tracing, with one thread per
    // pixel. The sample needs to align the number of threads to a multiple of the threadgroup
    // size, because earlier, when it created the pipeline objects, it declared that the pipeline
    // would always use a threadgroup size that's a multiple of the thread execution width
    // (SIMD group size). An 8x8 threadgroup is a safe threadgroup size and small enough for most devices to support.
    // A more advanced app can choose the threadgroup size dynamically.
    MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake((width  + threadsPerThreadgroup.width  - 1) / threadsPerThreadgroup.width,
                                       (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                       1);
    
    // Create a compute encoder to encode the GPU commands.
    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
    
    // Bind the buffers.
    [computeEncoder setBuffer:_uniformBuffer            offset:_uniformBufferOffset atIndex:0];
    [computeEncoder setBuffer:_instanceBuffer           offset:0                    atIndex:1];
    
    // Bind the acceleration structure and the intersection function table. These bind to normal buffer
    // binding slots.
    [computeEncoder setAccelerationStructure:_instanceAccelerationStructure atBufferIndex:2];
    [computeEncoder setIntersectionFunctionTable:_intersectionFunctionTable atBufferIndex:3];
    
    // Bind the instance transform matrices.
    [computeEncoder setBuffer:_transform offset:0 atIndex:4];
    
    // Bind the textures. The ray-tracing kernel reads from _accumulationTargets[0], averages the
    // result with this frame's samples, and writes to _accumulationTargets[1].
    [computeEncoder setTexture:_randomTexture atIndex:0];
    [computeEncoder setTexture:_accumulationTargets[0] atIndex:1];
    [computeEncoder setTexture:_accumulationTargets[1] atIndex:2];
    
    // Mark any resources that the intersection functions use as "used". The sample does this because
    // it only references these resources indirectly with the resource buffer. Metal makes all the
    // marked resources resident in memory before the intersection functions execute.
    // Usually, the sample also marks the resource buffer itself because the
    // intersection table references it indirectly. However, the sample also binds the resource
    // buffer directly, so it doesn't need to mark it explicitly.
    [computeEncoder useResource:_controlPointBuffer usage:MTLResourceUsageRead];
    [computeEncoder useResource:_curveIndexBuffer   usage:MTLResourceUsageRead];
    [computeEncoder useResource:_vertexNormalBuffer usage:MTLResourceUsageRead];
    [computeEncoder useResource:_vertexIndexBuffer  usage:MTLResourceUsageRead];
    
    // Also mark the primitive acceleration structures as "used" because only the instance acceleration
    // structure references them.
    for (id <MTLAccelerationStructure> primitiveAccelerationStructure in _primitiveAccelerationStructures)
        [computeEncoder useResource:primitiveAccelerationStructure usage:MTLResourceUsageRead];
    
    // Bind the compute pipeline state.
    [computeEncoder setComputePipelineState:_raytracingPipeline];
    
    // Dispatch the compute kernel to perform ray tracing.
    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];
    
    [computeEncoder endEncoding];
    
    // Swap the source and destination accumulation targets for the next frame.
    std::swap(_accumulationTargets[0], _accumulationTargets[1]);
    
    if (view.currentDrawable) {
        // Copy the resulting image into the view using the graphics pipeline because the sample
        // can't write directly to it using the compute kernel. The sample delays getting the
        // current render pass descriptor as long as possible to avoid a lengthy stall waiting
        // for the GPU/compositor to release a drawable. The drawable may be nil if
        // the window moves offscreen.
        MTLRenderPassDescriptor* renderPassDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
        
        renderPassDescriptor.colorAttachments[0].texture    = view.currentDrawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0f, 0.0f, 0.0f, 1.0f);
        
        // Create a render command encoder.
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        
        [renderEncoder setRenderPipelineState:_copyPipeline];
        
        [renderEncoder setFragmentTexture:_accumulationTargets[0] atIndex:0];
        
        // Draw a quad that fills the screen.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
        
        [renderEncoder endEncoding];
        
        // Present the drawable to the screen.
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    
    // Finally, commit the command buffer so that the GPU can start executing.
    [commandBuffer commit];
}

@end
