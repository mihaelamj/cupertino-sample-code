/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the Metal 4 renderer's methods that encode a render pass.
*/

#if !TARGET_OS_SIMULATOR

#import "Metal4Renderer+Encoding.h"
#import "ShaderTypes.h"
#import "TriangleData.h"

@implementation Metal4Renderer (Encoding)


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

/// Configures the viewport for a render pass.
///
/// The method sets the size to the same dimensions as the view's drawable region.
/// - Parameter renderPassEncoder: An encoder for a render pass.
- (void) setViewportSize:(simd_uint2) size
        forRenderEncoder:(id<MTL4RenderCommandEncoder>) renderPassEncoder
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

/// Configures the arguments for a render pass.
///
/// - Parameter renderPassEncoder: An encoder for a render pass.
///
/// The draw command in every render pass this app creates needs two arguments:
/// - The vertex position and color data for a triangle
/// - The size of the app's current viewport
///
/// The triangle data changes every frame.
/// The size of the viewport can change, but typically remains the same until a
/// person changes the size of the app or its window.
- (void) setRenderPassArguments:(id<MTL4RenderCommandEncoder>) renderPassEncoder
                       forFrame:(NSUInteger) frameNumber
                           with:(id<MTL4ArgumentTable>) argumentTable
                   vertexBuffer:(id<MTLBuffer>) vertexBuffer
                   viewPortSize:(id<MTLBuffer>) viewportSizeBuffer
{
    configureVertexDataForBuffer(frameNumber, vertexBuffer.contents);

    // Add the buffer with the triangle data to the argument table.
    [argumentTable setAddress:vertexBuffer.gpuAddress
                      atIndex:InputBufferIndexForVertexData];

    // Add the buffer with the viewport's size to the argument table.
    [argumentTable setAddress:viewportSizeBuffer.gpuAddress
                      atIndex:InputBufferIndexForViewportSize];

    // Assign the argument table to the encoder.
    [renderPassEncoder setArgumentTable:argumentTable
                               atStages:MTLRenderStageVertex];
}


/// Sends a command buffer to run on a Metal device by committing it to a
/// command queue.
///
/// - Parameters:
///   - commandBuffer: A command buffer with work for `view` that's ready to submit.
///   - commandQueue: A command queue the method submits the command buffer to.
///   - view: A MetalKit view instance, which provides a render target
/// with its `currentDrawable` property.
- (void) submitCommandBuffer:(id<MTL4CommandBuffer>) commandBuffer
              toCommandQueue:(id<MTL4CommandQueue>) commandQueue
                     forView:(nonnull MTKView *) view
{
    /// A drawable from the view that the method renders the frame to.
    id<CAMetalDrawable> currentDrawable = view.currentDrawable;

    // Instruct the queue to wait until the drawable is ready to receive output from the render pass.
    [commandQueue waitForDrawable:currentDrawable];

    // Run the command buffer on the GPU by submitting it the Metal device's queue.
    [commandQueue commit:&commandBuffer count:1];

    // Notify the drawable that the GPU is done running the render pass.
    [commandQueue signalDrawable:currentDrawable];

    // Instruct the drawable to show itself on the device's display when the render pass completes.
    [currentDrawable present];
}

@end

#endif
