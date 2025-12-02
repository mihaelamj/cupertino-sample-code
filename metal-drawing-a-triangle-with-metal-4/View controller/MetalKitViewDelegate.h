/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface for the app's MetalKit view delegate.
*/

#import <MetalKit/MetalKit.h>

/// A delegate for MetalKit view's that decouples a view controller from the
/// renderer that draws each frame.
@interface MetalKitViewDelegate : NSObject<MTKViewDelegate>

/// Creates a delegate for a MetalKit view.
/// - Parameter view: A view that the delegate works with.
- (nonnull instancetype) initWithMetalKitView:(nonnull MTKView *) view;
@end
