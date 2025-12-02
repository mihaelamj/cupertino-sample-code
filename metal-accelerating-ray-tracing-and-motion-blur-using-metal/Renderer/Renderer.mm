/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the renderer class that performs Metal setup and per-frame rendering.
*/

#import <simd/simd.h>

#import "Renderer.h"
#import "Transforms.h"
#import "ShaderTypes.h"
#import "Scene.h"

using namespace simd;

static const NSUInteger kMaxFramesInFlight = 3;

@implementation Renderer
{
    id <MTLDevice> _device;
    id <MTLCommandQueue> _queue;
    id <MTLLibrary> _library;

    id <MTLBuffer> _frameDataBuffers[kMaxFramesInFlight];
    NSUInteger _frameDataIndex;

    id <MTLAccelerationStructure> _instanceAccelerationStructure;
    NSMutableArray *_primitiveAccelerationStructures;

    id <MTLComputePipelineState> _raytracingPipeline;
    id <MTLRenderPipelineState> _copyPipeline;

    id <MTLTexture> _accumulationTargets[2];
    id <MTLTexture> _randomTexture;

    id <MTLBuffer> _resourceBuffer;
    id <MTLBuffer> _instanceBuffer;
    id <MTLBuffer> _transformBuffer;

    dispatch_semaphore_t _sem;
    CGSize _drawableSize;

    unsigned int _frameIndex;

    Scene *_scene;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
                                 scene:(Scene *)scene
                    usePrimitiveMotion:(BOOL)usePrimitiveMotion
{
    self = [super init];

    if (self)
    {
        _device = device;

        _sem = dispatch_semaphore_create(kMaxFramesInFlight);

        _scene = scene;

        [self loadMetal];
        [self createBuffers];
        [self createAccelerationStructures];
        [self createPipelinesWithPrimitiveMotion:usePrimitiveMotion];
    }

    return self;
}

// Initialize the Metal shader library and command queue.
- (void)loadMetal
{
    _library = [_device newDefaultLibrary];

    _queue = [_device newCommandQueue];
}

// Create a compute pipeline state.
- (id <MTLComputePipelineState>)newComputePipelineStateWithFunction:(id <MTLFunction>)function
{
    MTLComputePipelineDescriptor *descriptor = [[MTLComputePipelineDescriptor alloc] init];

    // Set the compute function.
    descriptor.computeFunction = function;

    // Set to YES to allow the compiler to make certain optimizations.
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

// Create the pipeline states.
- (void)createPipelinesWithPrimitiveMotion:(BOOL)usePrimitiveMotion
{
    id <MTLFunction> raytracingFunction = [_library newFunctionWithName:usePrimitiveMotion ?
                                           @"raytracingInstanceAndPrimitiveMotionKernel" : @"raytracingInstanceMotionKernel"];

    // Create the compute pipeline state, which does all of the ray tracing.
    _raytracingPipeline = [self newComputePipelineStateWithFunction:raytracingFunction];

    // Create a render pipeline state, which copies the rendered scene into the MTKView and
    // performs simple tone mapping.
    MTLRenderPipelineDescriptor *renderDescriptor = [[MTLRenderPipelineDescriptor alloc] init];

    renderDescriptor.vertexFunction = [_library newFunctionWithName:@"copyVertex"];
    renderDescriptor.fragmentFunction = [_library newFunctionWithName:@"copyFragment"];

    renderDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;

    NSError *error;

    _copyPipeline = [_device newRenderPipelineStateWithDescriptor:renderDescriptor error:&error];

    NSAssert(_copyPipeline, @"Failed to create %@ pipeline state: %@", raytracingFunction.name, error);
}

- (void)createBuffers
{
    MTLResourceOptions options = getManagedBufferStorageMode();
    
    for(NSUInteger i = 0; i < kMaxFramesInFlight; i++)
    {
        _frameDataBuffers[i] = [_device newBufferWithLength:sizeof(FrameData)
                                                  options:options];

        _frameDataBuffers[i].label = [NSString stringWithFormat:@"FrameDataBuffer%lu", i];
    }

    // Upload scene data to the buffers.
    [_scene uploadToBuffers];

    NSUInteger resourcesStride = _scene.geometries[0].resourcesStride;

    // Create the resource buffer. This buffer contains pointers to each geometry's resources.
    _resourceBuffer = [_device newBufferWithLength:resourcesStride * _scene.geometries.count options:options];

    _resourceBuffer.label = @"Resource Buffer";
    for (NSUInteger geometryIndex = 0; geometryIndex < _scene.geometries.count; geometryIndex++)
    {
        Geometry *geometry = _scene.geometries[geometryIndex];
        
        // Encode the geometry's resources into the resource buffer so that the Metal shaders
        // can access them.
        [geometry encodeResourcesToBuffer:_resourceBuffer
                                   offset:geometryIndex * resourcesStride];
    }

#if !TARGET_OS_IPHONE
    [_resourceBuffer didModifyRange:NSMakeRange(0, _resourceBuffer.length)];
#endif
}

// Create and compact an acceleration structure, given an acceleration structure descriptor.
- (id <MTLAccelerationStructure>)newAccelerationStructureWithDescriptor:(MTLAccelerationStructureDescriptor *)descriptor
{
    // Query for the sizes needed to store and build the acceleration structure.
    MTLAccelerationStructureSizes accelSizes = [_device accelerationStructureSizesWithDescriptor:descriptor];

    // Allocate an acceleration structure large enough for this descriptor. This doesn't actually
    // build the acceleration structure, it just allocates memory.
    id <MTLAccelerationStructure> accelerationStructure = [_device newAccelerationStructureWithSize:accelSizes.accelerationStructureSize];

    // Allocate scratch space Metal uses to build the acceleration structure.
    // Use MTLResourceStorageModePrivate for best performance because the sample
    // doesn't need access to the buffer's contents.
    id <MTLBuffer> scratchBuffer = [_device newBufferWithLength:accelSizes.buildScratchBufferSize options:MTLResourceStorageModePrivate];

    // Create a command buffer to perform the acceleration structure build.
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
    // need to already have a built accelerated structure because Metal determines the compacted
    // size based on the final size of the acceleration structure. Compacting an acceleration
    // structure can potentially reclaim significant amounts of memory because Metal must
    // create the initial structure using a conservative approach.

    [commandEncoder writeCompactedAccelerationStructureSize:accelerationStructure
                                                   toBuffer:compactedSizeBuffer
                                                     offset:0];

    // End encoding and commit the command buffer so the GPU can start building the
    // acceleration structure.
    [commandEncoder endEncoding];

    [commandBuffer commit];

    // The sample waits for Metal to finish executing the command buffer so that it can
    // read back the compacted size.

    // Note: Don't wait for Metal to finish executing the command buffer if you aren't compacting
    // the acceleration structure because doing so requires CPU/GPU synchronization. You don't have
    // to compact acceleration structures, but it's helpful when creating large static acceleration
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
// contain primitives, such as triangles and spheres. The instance acceleration structure contains
// copies or "instances" of the primitive acceleration structures, each with their own
// transformation matrix describing where to place them in the scene.
- (void)createAccelerationStructures
{
    MTLResourceOptions options = getManagedBufferStorageMode();

    _primitiveAccelerationStructures = [[NSMutableArray alloc] init];

    // Create a primitive acceleration structure for each piece of geometry in the scene.
    for (NSUInteger i = 0; i < _scene.geometries.count; i++)
    {
        Geometry *mesh = _scene.geometries[i];

        MTLPrimitiveAccelerationStructureDescriptor *accelDescriptor = [mesh accelerationStructureDescriptor];

        // Build the acceleration structure.
        id <MTLAccelerationStructure> accelerationStructure = [self newAccelerationStructureWithDescriptor:accelDescriptor];

        // Add the acceleration structure to the array of primitive acceleration structures.
        [_primitiveAccelerationStructures addObject:accelerationStructure];
    }

    // Allocate a buffer of acceleration structure motion instance descriptors. Each descriptor
    // represents an instance of one of the primitive acceleration structures created above, with
    // its own set of transformation matrices representing where to place the instance in the scene
    // for each keyframe.
    _instanceBuffer = [_device newBufferWithLength:sizeof(MTLAccelerationStructureMotionInstanceDescriptor) * _scene.instances.count options:options];
    _instanceBuffer.label = @"Instance Buffer";
    
    // Create a motion instance acceleration structure descriptor that supports instance-level motion.
    MTLAccelerationStructureMotionInstanceDescriptor *instanceDescriptors = (MTLAccelerationStructureMotionInstanceDescriptor *)_instanceBuffer.contents;
    
    NSUInteger transformCount = 0;
    
    for (NSUInteger instanceIndex = 0; instanceIndex < _scene.instances.count; instanceIndex++)
        transformCount += _scene.instances[instanceIndex].instanceMotionKeyframeCount;
    
    // Allocate a buffer to store the instance transformation matrices for each keyframe.
    _transformBuffer = [_device newBufferWithLength:sizeof(MTLPackedFloat4x3) * transformCount options:options];
    
    MTLPackedFloat4x3 *transforms = (MTLPackedFloat4x3 *)_transformBuffer.contents;
    
    NSUInteger transformIndex = 0;

    // Fill out the instance descriptors.
    for (NSUInteger instanceIndex = 0; instanceIndex < _scene.instances.count; instanceIndex++)
    {
        GeometryInstance *instance = _scene.instances[instanceIndex];

        NSUInteger geometryIndex = [_scene.geometries indexOfObject:instance.geometry];

        // Create a motion instance descriptor.
        MTLAccelerationStructureMotionInstanceDescriptor & descriptor = instanceDescriptors[instanceIndex];

        // Map the instance to its acceleration structure.
        descriptor.accelerationStructureIndex = (uint32_t)geometryIndex;

        // Mark the instance as opaque because it doesn't have an intersection function so that the
        // ray intersector doesn't attempt to execute a function that doesn't exist.
        descriptor.options = MTLAccelerationStructureInstanceOptionOpaque;
        descriptor.intersectionFunctionTableOffset = 0;

        // Set the instance mask, which the sample uses to filter out intersections between rays
        // and geometry. For example, it uses masks to prevent light sources from being visible
        // to secondary rays, which results in their contribution being double-counted.
        descriptor.mask = (uint32_t)instance.mask;
        
        // The motion blur parameters.
        descriptor.motionStartBorderMode = MTLMotionBorderModeClamp;
        descriptor.motionEndBorderMode = MTLMotionBorderModeClamp;
        
        descriptor.motionStartTime = 0.0f;
        descriptor.motionEndTime = 1.0f;
        
        // These properties reference the transformation matrices that the transform buffer stores.
        descriptor.motionTransformsCount = (uint32_t)instance.instanceMotionKeyframeCount;
        descriptor.motionTransformsStartIndex = (uint32_t)transformIndex;
        
        // Encode the transformation matrices for each keyframe.
        for (NSUInteger keyframeIndex = 0; keyframeIndex < instance.instanceMotionKeyframeCount; keyframeIndex++) {
            MTLPackedFloat4x3 transform;

            // Copy the first three rows of the instance transformation matrix. Metal assumes that
            // the bottom row is (0, 0, 0, 1).
            // This allows instance descriptors to be tightly packed in memory.
            for (int column = 0; column < 4; column++)
                for (int row = 0; row < 3; row++)
                    transform.columns[column][row] = instance.transforms[keyframeIndex].columns[column][row];
        
            transforms[transformIndex++] = transform;
        }
    }

#if !TARGET_OS_IPHONE
    [_instanceBuffer didModifyRange:NSMakeRange(0, _instanceBuffer.length)];
    [_transformBuffer didModifyRange:NSMakeRange(0, _transformBuffer.length)];
#endif

    // Create an instance acceleration structure descriptor.
    MTLInstanceAccelerationStructureDescriptor *accelDescriptor = [MTLInstanceAccelerationStructureDescriptor descriptor];

    accelDescriptor.instancedAccelerationStructures = _primitiveAccelerationStructures;
    accelDescriptor.instanceCount = _scene.instances.count;
    accelDescriptor.instanceDescriptorBuffer = _instanceBuffer;
    accelDescriptor.motionTransformBuffer = _transformBuffer;
    accelDescriptor.motionTransformCount = transformCount;

    // Specify that the sample is using the motion instance descriptor type rather than the default descriptor.
    accelDescriptor.instanceDescriptorType = MTLAccelerationStructureInstanceDescriptorTypeMotion;
    
    // Create the instance acceleration structure that contains all of the instances in the scene.
    _instanceAccelerationStructure = [self newAccelerationStructureWithDescriptor:accelDescriptor];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _drawableSize = size;

    // Create a pair of textures, which the ray tracing kernel uses to accumulate
    // samples over several frames.
    MTLTextureDescriptor *textureDescriptor = [[MTLTextureDescriptor alloc] init];

    textureDescriptor.pixelFormat = MTLPixelFormatRGBA32Float;
    textureDescriptor.textureType = MTLTextureType2D;
    textureDescriptor.width = size.width;
    textureDescriptor.height = size.height;

    // Store this in private memory because only the GPU reads or writes to this texture.
    textureDescriptor.storageMode = MTLStorageModePrivate;
    textureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;

    for (NSUInteger i = 0; i < 2; i++)
        _accumulationTargets[i] = [_device newTextureWithDescriptor:textureDescriptor];

    // Create a texture that contains a random integer value for each pixel.  The sample
    // uses these values to decorrelate pixels while drawing pseudorandom numbers from the
    // Halton sequence.
    textureDescriptor.pixelFormat = MTLPixelFormatR32Uint;
    textureDescriptor.usage = MTLTextureUsageShaderRead;

    // The sample initializes the data in the texture, so it can't be private.
#if !TARGET_OS_IPHONE
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

- (void)updateFrameData
{
    _frameDataIndex = (_frameDataIndex + 1) % kMaxFramesInFlight;
    
    FrameData *frameData =  (FrameData *)_frameDataBuffers[_frameDataIndex].contents;

    vector_float3 position = _scene.cameraPosition;
    vector_float3 target = _scene.cameraTarget;
    vector_float3 up = _scene.cameraUp;

    vector_float3 forward = vector_normalize(target - position);
    vector_float3 right = vector_normalize(vector_cross(forward, up));
    up = vector_normalize(vector_cross(right, forward));

    frameData->camera.position = position;
    frameData->camera.forward = forward;
    frameData->camera.right = right;
    frameData->camera.up = up;

    float fieldOfView = 45.0f * (M_PI / 180.0f);
    float aspectRatio = (float)_drawableSize.width / (float)_drawableSize.height;
    float imagePlaneHeight = tanf(fieldOfView / 2.0f);
    float imagePlaneWidth = aspectRatio * imagePlaneHeight;

    frameData->camera.right *= imagePlaneWidth;
    frameData->camera.up *= imagePlaneHeight;

    frameData->width = (unsigned int)_drawableSize.width;
    frameData->height = (unsigned int)_drawableSize.height;

    frameData->frameIndex = _frameIndex++;

    frameData->lightCount = (unsigned int)_scene.lightCount;

#if !TARGET_OS_IPHONE
    [_frameDataBuffers[_frameDataIndex] didModifyRange:NSMakeRange(0, sizeof(FrameData))];
#endif
}

- (void)drawInMTKView:(MTKView *)view
{
    dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);

    // Create a command buffer for the frame's commands.
    id <MTLCommandBuffer> commandBuffer = [_queue commandBuffer];

    __block dispatch_semaphore_t sem = _sem;

    // Note: Completion handlers need to be as fast as possible because the GPU
    // driver may have other work scheduled on the underlying dispatch queue.
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(sem);
    }];

    [self updateFrameData];

    NSUInteger width = (NSUInteger)_drawableSize.width;
    NSUInteger height = (NSUInteger)_drawableSize.height;

    // Launch a rectangular grid of threads on the GPU to perform ray tracing, with one thread per
    // pixel.  The sample needs to align the number of threads to a multiple of the threadgroup
    // size, because earlier, when it creates the pipeline objects, it declares that the pipeline
    // always uses a threadgroup size that's a multiple of the thread execution width (SIMD group size).
    // An 8x8 threadgroup is a safe threadgroup size and small enough for most devices to support.
    // A more advanced app can dynamically choose the threadgroup size.
    MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake((width  + threadsPerThreadgroup.width  - 1) / threadsPerThreadgroup.width,
                                       (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                       1);

    // Create a compute encoder to encode GPU commands.
    id <MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];

    // Bind buffers.
    [computeEncoder setBuffer:_frameDataBuffers[_frameDataIndex] offset:0 atIndex:0];
    [computeEncoder setBuffer:_resourceBuffer                    offset:0 atIndex:1];
    [computeEncoder setBuffer:_instanceBuffer                    offset:0 atIndex:2];
    [computeEncoder setBuffer:_scene.lightBuffer                 offset:0 atIndex:3];

    // Bind the acceleration structure to a normal buffer binding slot.
    [computeEncoder setAccelerationStructure:_instanceAccelerationStructure atBufferIndex:4];

    // Bind the textures. The ray tracing kernel reads from `_accumulationTargets[0]`, averages the
    // result with this frame's samples, and writes to `_accumulationTargets[1]`.
    [computeEncoder setTexture:_randomTexture atIndex:0];
    [computeEncoder setTexture:_accumulationTargets[0] atIndex:1];
    [computeEncoder setTexture:_accumulationTargets[1] atIndex:2];

    // Mark any resources that the argument buffers reference only indirectly through
    // other argument buffers as "used".  Metal makes all the marked resources resident
    // in memory before the compute kernel executes.
    for (Geometry *geometry in _scene.geometries)
        [geometry markResourcesAsUsedWithEncoder:computeEncoder];
    
    // Also mark primitive acceleration structures as "used" because only the instance acceleration
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

    if (view.currentDrawable)
    {
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

    // Commit the command buffer so that the GPU can start executing.
    [commandBuffer commit];
}

@end
