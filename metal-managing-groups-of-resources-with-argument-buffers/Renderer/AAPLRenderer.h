/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the renderer class that performs Metal setup and per-frame rendering.
*/

#import <MetalKit/MetalKit.h>

// The platform-independent renderer class.
@interface AAPLRenderer : NSObject<MTKViewDelegate>

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView;

@end
