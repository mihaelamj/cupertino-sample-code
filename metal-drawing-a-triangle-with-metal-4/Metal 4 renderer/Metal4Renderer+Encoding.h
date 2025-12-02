/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface for the Metal 4 renderer's methods that encode a render pass.
*/

#if !TARGET_OS_SIMULATOR

#import "Metal4Renderer.h"

@interface Metal4Renderer (Encoding)

- (void) waitOnSharedEvent:(nonnull id<MTLSharedEvent>) sharedEvent
           forEarlierFrame:(uint64_t) earlierFrameNumber;

- (void) setViewportSize:(simd_uint2) size
        forRenderEncoder:(nonnull id<MTL4RenderCommandEncoder>) renderPassEncoder;

- (void) setRenderPassArguments:(nonnull id<MTL4RenderCommandEncoder>) renderPassEncoder
                       forFrame:(NSUInteger) frameNumber
                           with:(nonnull id<MTL4ArgumentTable>) argumentTable
                   vertexBuffer:(nonnull id<MTLBuffer>) vertexBuffer
                   viewPortSize:(nonnull id<MTLBuffer>) viewportSizeBuffer;

- (void) submitCommandBuffer:(nonnull id<MTL4CommandBuffer>) commandBuffer
              toCommandQueue:(nonnull id<MTL4CommandQueue>) commandQueue
                     forView:(nonnull MTKView *) view;
@end

#endif
