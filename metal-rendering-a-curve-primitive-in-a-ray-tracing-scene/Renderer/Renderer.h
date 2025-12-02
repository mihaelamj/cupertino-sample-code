/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the renderer class that performs Metal setup and per-frame rendering.
*/

#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface Renderer : NSObject <MTKViewDelegate>

- (instancetype)initWithDevice:(id<MTLDevice>)device;

@end
