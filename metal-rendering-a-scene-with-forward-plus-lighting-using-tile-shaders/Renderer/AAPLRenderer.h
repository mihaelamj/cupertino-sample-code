/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for renderer class that perfoms Metal setup and per-frame rendering.
*/

@import MetalKit;

@interface AAPLRenderer : NSObject <MTKViewDelegate>

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;

@end


