/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A platform-independent Metal renderer implementation that sets up the app's
 resources once and then draws each frame.
*/

#import "MetalRenderer.h"
#import "TriangleData.h"
#import "MetalRenderer+Setup.h"
#import "MetalRenderer+Compilation.h"

/// The number of frames the renderer works with at the same time.
#define kMaxFramesInFlight 3

/// A class that renders each of the app's video frames.
@implementation MetalRenderer
{
    /// A command queue the app uses to send command buffers to the Metal device.
    id<MTLCommandQueue> commandQueue;

    /// A shared event that synchronizes work that runs on the CPU and GPU.
    ///
    /// The app instructs the GPU to signal the main code on the CPU when it
    /// finishes rendering a frame.
    id<MTLSharedEvent> sharedEvent;

    /// An integer that tracks the current frame number.
    uint64_t frameNumber;

    /// The current size of the view.
    simd_uint2 viewportSize;

    /// A buffer that stores the viewport's size data.
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

/// Initializes the Metal renderer with a MetalKit view.
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

    // The renderer only works with the Metal device the app assigns to the view.
    _device = view.device;
    commandQueue = [self.device newCommandQueue];

    // Create the essential resources.
    renderPipelineState = [self compileRenderPipeline:view.colorPixelFormat];
    triangleVertexBuffers = [self makeTriangleDataBuffers:kMaxFramesInFlight];
    viewportSizeBuffer = [self.device newBufferWithLength:sizeof(viewportSize)
                                                  options:MTLResourceStorageModeShared];

    // Initialize the renderer with the view's drawable size.
    [self updateViewportSize:view.drawableSize];

    // Set the frame number to `0`, which sets up the first frame to get the number `1`.
    frameNumber = 0;

    // Create a shared event that starts at zero.
    sharedEvent = [self.device newSharedEvent];
    sharedEvent.signaledValue = frameNumber;

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

/// Pauses the CPU when the device is rendering a previous frame that needs the resources
/// that the renderer is about to reuse for a frame.
///
/// The method adds a command that waits for a signal from the command queue that
/// indicates when the Metal device is done rendering an earlier frame.
/// This signal means the renderer can safely reuse the resources for that prior frame.
- (void) waitOnSharedEvent:(id<MTLSharedEvent>) sharedEvent
           forEarlierFrame:(uint64_t) earlierFrameNumber
{
    const uint64_t tenMilliseconds = 10;

    // Wait for the GPU to finish rendering the frame that's
    // `kMaxFramesInFlight` before this one, and then proceed to the next step.
    BOOL beforeTimeout = [sharedEvent waitUntilSignaledValue:earlierFrameNumber
                                                   timeoutMS:tenMilliseconds];

    if (false == beforeTimeout) {
        NSLog(@"No signal from frame %llu to shared event after %llums",
              earlierFrameNumber, tenMilliseconds);
    }
}

/// Draws a frame of content to a view's drawable.
/// - Parameter view: A view with a drawable that the renderer draws into.
- (void) renderFrameToView:(nonnull MTKView *) view
{
    NSAssert(view.device == commandQueue.device,
             @"The view's Metal device isn't the same as the render device.");

    // Get the render pass descriptor from the view's drawable instance.
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (nil == renderPassDescriptor) { return; }

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

    // Create a new command buffer from the queue.
    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
    commandBuffer.label = label;

    // Configure the render pass descriptor from the drawable's instance.
    id<MTLRenderCommandEncoder> renderEncoder;
    renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    renderEncoder.label = label;

    [self setViewportSize:viewportSize forRenderEncoder:renderEncoder];

    // Configure the encoder with the renderer's main pipeline state.
    [renderEncoder setRenderPipelineState:renderPipelineState];

    // Update the positions of the triangles.
    id<MTLBuffer> vertexBuffer = triangleVertexBuffers[frameIndex];
    configureVertexDataForBuffer(frameNumber, vertexBuffer.contents);

    // Bind the triangle's vertex data to the encoder's vertex data index.
    [renderEncoder setVertexBuffer:vertexBuffer
                            offset:0
                           atIndex:InputBufferIndexForVertexData];

    // Bind the viewport's size data to the encoder's viewport index.
    [renderEncoder setVertexBuffer:viewportSizeBuffer
                            offset:0
                           atIndex:InputBufferIndexForViewportSize];

    // Draw the triangle.
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:3];

    // Finalize the render pass.
    [renderEncoder endEncoding];

    // Instruct the drawable to show itself on the device's display when the render pass completes.
    [commandBuffer presentDrawable:view.currentDrawable];

    // Signal when the GPU finishes rendering this frame with a shared event.
    [commandBuffer encodeSignalEvent:sharedEvent value:frameNumber];

    // Submit the command buffer to the GPU.
    [commandBuffer commit];
}

/// Configures the viewport for a render pass.
///
/// The method sets the size to the same dimensions as the view's drawable region.
/// - Parameter renderPassEncoder: An encoder for a render pass.
- (void) setViewportSize:(simd_uint2) size
        forRenderEncoder:(id<MTLRenderCommandEncoder>) renderPassEncoder
{
    // Configure the viewport with the size of the drawable region.
    MTLViewport viewPort;
    viewPort.originX = 0.0;
    viewPort.originY = 0.0;
    viewPort.znear = 0.0;
    viewPort.zfar = 1.0;
    viewPort.width = (double)size.x;
    viewPort.height = (double)size.y;

    [renderPassEncoder setViewport:viewPort];
}
@end
