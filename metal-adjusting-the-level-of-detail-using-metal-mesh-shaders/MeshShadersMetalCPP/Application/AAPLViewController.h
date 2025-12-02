/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform view controller.
*/

#import <TargetConditionals.h>
@import MetalKit;

#if TARGET_OS_OSX

@import AppKit;
#define PlatformViewController NSViewController<MTKViewDelegate>

#elif TARGET_OS_IPHONE

@import UIKit;
#define PlatformViewController UIViewController<MTKViewDelegate>

#endif

/// A view controller that implements MetalKit's view delegate protocol.
@interface AAPLViewController : PlatformViewController

@end
