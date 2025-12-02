/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface for the renderer class, which sets up Metal renders every frame.
*/

@import MetalKit;

/// A renderer for systems that support Metal 4 GPUs.
@interface Metal4Renderer : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithView:(nonnull MTKView *)mtkView;

@end
