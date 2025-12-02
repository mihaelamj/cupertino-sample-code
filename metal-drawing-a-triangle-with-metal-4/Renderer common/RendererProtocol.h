/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol interface for renderer types.
*/

#import <MetalKit/MetalKit.h>

/// A minimal interface for a renderer type.
@protocol Renderer <NSObject>

- (nonnull instancetype) initWithMetalKitView:(nonnull MTKView *) view;

/// Informs the renderer when the size of the view changes.
/// - Parameter size: The new viewport size.
- (void) updateViewportSize:(CGSize) size;

/// Instructs the renderer to draw a frame for a view.
/// - Parameter view: A view the renderer draws to, which provides:
///     - A render pass descriptor that reflects the view's current configuration
///     - A drawable instance that the render draws to
- (void) renderFrameToView:(nonnull MTKView *) view;

@end

