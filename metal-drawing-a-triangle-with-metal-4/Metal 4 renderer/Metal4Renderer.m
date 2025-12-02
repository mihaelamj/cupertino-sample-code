/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A platform-independent Metal 4 renderer implementation that sets up the app's
 resources once and then draws each frame.
*/

#if !TARGET_OS_SIMULATOR

#import "Metal4Renderer.h"
#import "Metal4Renderer+Setup.h"
#import "Metal4Renderer+Compilation.h"
#import "Metal4Renderer+Encoding.h"

// The shader types header that defines the input data types for the app's shaders.
// The types define a common data format for both
// the `.metal` shader source code files, which run on the GPU,
// and the code in this file, which sets up input data with the Metal API on the CPU.
#import "ShaderTypes.h"

/// The number of frames the renderer works with at the same time.
#define kMaxFramesInFlight 3

/// A class that renders each of the app's video frames.
@implementation Metal4Renderer
{
    /// A command queue the app uses to send command buffers to the Metal device.
    id<MTL4CommandQueue> commandQueue;

    /// A command buffer the app reuses to render each frame.
    id<MTL4CommandBuffer> commandBuffer;

    /// An array of allocators that store commands for each frame
    /// while the app encodes them and the GPU runs them.
    NSArray<id<MTL4CommandAllocator>> *commandAllocators;

    /// An argument table that stores the resource bindings for a render encoder.
    id<MTL4ArgumentTable> argumentTable;

    /// A residency set that keeps resources in memory for the app's lifetime.
    id<MTLResidencySet> residencySet;

    /// A shared event that synchronizes work that runs on the CPU and GPU.
    ///
    /// The app instructs the GPU to signal the main code on the CPU when it
    /// finishes rendering a frame.
    id<MTLSharedEvent> sharedEvent;

    /// An integer that tracks the current frame number.
    uint64_t frameNumber;

    /// The current size of the view.
    simd_uint2 viewportSize;

    /// A buffer that stores the size of the app's viewport.
    ///
    /// The renderer sends this buffer as an input to the vertex shader.
    id<MTLBuffer> viewportSizeBuffer;

    /// An array of buffers, each of which stores the geometric position and color
    /// data of a triangle's three vertices for one frame.
    ///
    /// The renderer sends one of these buffers, per frame, as an input to the vertex shader.
    NSArray<id<MTLBuffer>> *triangleVertexBuffers;

    /// A render pipeline the app creates at runtime.
    ///
    /// The app creates the pipeline with the vertex and fragment shaders in the
    /// `Shaders.metal` source code file.
    id<MTLRenderPipelineState> renderPipelineState;
}


// MARK: - Renderer protocol methods

/// Initializes the Metal 4 renderer with a MetalKit view.
/// - Parameter view: A view from the MetalKit framework.
///
/// MetalKit views have convenient methods and properties that provide context,
/// including:
/// - A pixel format, which the renderer needs to build its rendering pipeline
/// - A `CAMetalDrawable` instance, which provides a rendering destination
- (nonnull instancetype) initWithMetalKitView:(nonnull MTKView *) view
{
    self = [super init];
    if (nil == self) { return nil; }

    // Retrieve the Metal device instance from the view.
    _device = view.device;

    // Create a command queue from the device.
    commandQueue = [self.device newMTL4CommandQueue];

    // Create the command buffer from the device.
    commandBuffer = [self.device newCommandBuffer];

    // Create a default library instance, which contains the project's shaders.
    _defaultLibrary = [self.device newDefaultLibrary];

    // Create the essential resources.
    triangleVertexBuffers = [self makeTriangleDataBuffers:kMaxFramesInFlight];
    argumentTable = [self makeArgumentTable];
    residencySet = [self makeResidencySet];
    commandAllocators = [self makeCommandAllocators:kMaxFramesInFlight];

    viewportSizeBuffer = [self.device newBufferWithLength:sizeof(viewportSize)
                                                  options:MTLResourceStorageModeShared];

    // Compile a render pipeline state for the view.
    renderPipelineState = [self compileRenderPipeline:view.colorPixelFormat];

    // Set the frame number to `0`, which sets up the first frame to get the number `1`.
    frameNumber = 0;

    // Create a shared event that starts at zero.
    sharedEvent = [self.device newSharedEvent];
    sharedEvent.signaledValue = frameNumber;

    // Add the viewport size buffer to the residency set.
    [residencySet addAllocation:viewportSizeBuffer];

    // Add the buffers that store the triangle vertex data to the residency set.
    for (id<MTLBuffer> triangleVertexBuffer in triangleVertexBuffers) {
        [residencySet addAllocation:triangleVertexBuffer];
    }

    // Apply the updates to the residency set.
    [residencySet commit];

    // Make the resources in the long-term residency set accessible to the GPU
    // when it runs any command buffer the app submits to the command queue.
    [commandQueue addResidencySet:residencySet];

    // Make the resources in the view's residency set accessible to the GPU
    // when it runs any command buffer the app submits to the command queue.
    [commandQueue addResidencySet:((CAMetalLayer *)view.layer).residencySet];

    // Initialize the renderer with the view's drawable size.
    [self updateViewportSize:view.drawableSize];

    return self;
}

/// Notifies the renderer when the system changes the size of the app's visible area.
/// - Parameter size: The dimensions of the app's visible area.
- (void) updateViewportSize:(CGSize) size
{
    // Update the viewport property to its new size,
    // which the renderer passes to the vertex shader.
    viewportSize.x = size.width;
    viewportSize.y = size.height;

    // Update the buffer that stores the viewport's size.
    memcpy(viewportSizeBuffer.contents, &viewportSize, sizeof(viewportSize));
}

/// Draws a frame of content to a view's drawable.
///
/// - Parameter view: A view with a drawable that the renderer draws into.
- (void) renderFrameToView:(nonnull MTKView *) view
{
    if ([self isMissingRequirementsFromView:view]) { return; }

    // Increment the frame number for this frame.
    frameNumber += 1;

    const uint32_t frameIndex = frameNumber % kMaxFramesInFlight;
    NSString *label = [NSString stringWithFormat:@"Frame: %llu", frameNumber];

    // The renderer skips waiting for the first `kMaxFramesInFlight` frames.
    // There aren't any earlier frames to wait for because they're the first.
    if (frameNumber > kMaxFramesInFlight) {
        // Wait for the oldest frame in flight to finish rendering before reusing its resources.
        [self waitOnSharedEvent:sharedEvent
                forEarlierFrame:frameNumber - kMaxFramesInFlight];
    }

    // Prepare to use or reuse the allocator by resetting it.
    id<MTL4CommandAllocator> frameAllocator = commandAllocators[frameIndex];
    [frameAllocator reset];

    // Prepare to use or reuse the command buffer for the frame's commands.
    [commandBuffer beginCommandBufferWithAllocator:frameAllocator];
    commandBuffer.label = label;

    // Create a render pass encoder from the command buffer with the view's configuration.
    id<MTL4RenderCommandEncoder> renderPassEncoder;
    MTL4RenderPassDescriptor *configuration = view.currentMTL4RenderPassDescriptor;
    renderPassEncoder = [commandBuffer renderCommandEncoderWithDescriptor:configuration];
    renderPassEncoder.label = label;

    // Configure the encoder with the renderer pipeline state.
    [renderPassEncoder setRenderPipelineState:renderPipelineState];

    [self setViewportSize:viewportSize forRenderEncoder:renderPassEncoder];
    [self setRenderPassArguments:renderPassEncoder
                        forFrame:frameNumber
                            with:argumentTable
                    vertexBuffer:triangleVertexBuffers[frameIndex]
                    viewPortSize:viewportSizeBuffer];

    // Draw the triangle.
    [renderPassEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:3];

    // Finalize the render pass.
    [renderPassEncoder endEncoding];

    // Submit the command buffer to the GPU.
    [commandBuffer endCommandBuffer];

    [self submitCommandBuffer:commandBuffer
               toCommandQueue:commandQueue
                      forView:view];

    // Signal when the GPU finishes rendering this frame with a shared event.
    [commandQueue signalEvent:sharedEvent value:frameNumber];
}

- (BOOL) isMissingRequirementsFromView:(nonnull MTKView *) view {
    BOOL drawableMissing = false;
    BOOL renderPassDescriptorMissing = false;

    if (nil == view.currentDrawable)
    {
        NSLog(@"The view doesn't have a current drawable instance.");
        drawableMissing = true;
    }

    if (nil == view.currentMTL4RenderPassDescriptor)
    {
        NSLog(@"The view doesn't have a render pass descriptor for Metal 4.");
        renderPassDescriptorMissing = true;
    }

    return drawableMissing || renderPassDescriptorMissing;
}

@end

#endif
