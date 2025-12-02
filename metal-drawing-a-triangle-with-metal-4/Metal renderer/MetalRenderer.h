/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface for the Metal renderer.
*/

#import "RendererProtocol.h"

/// A renderer for systems that support Metal GPUs.
///
/// The renderer applies to systems with Metal versions 1, 2, and 3.
@interface MetalRenderer : NSObject<Renderer>

/// The Metal device the renderer draws with by sending commands to it.
///
/// The device instance also creates various resources the renderer needs to
/// encode and submit its commands.
@property (nonatomic, readonly) id<MTLDevice> device;

@end
