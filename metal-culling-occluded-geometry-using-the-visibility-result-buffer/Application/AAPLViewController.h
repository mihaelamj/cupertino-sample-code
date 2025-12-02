/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform view controller.
*/

#if defined(TARGET_MACOS)
@import AppKit;
#define PlatformViewController NSViewController
#elif defined(TARGET_IOS) || defined (TARGET_TVOS)
@import UIKit;
#define PlatformViewController UIViewController
#endif

@import MetalKit;
#import "AAPLRenderer.h"

// This is the app's cross-platform view controller.
@interface AAPLViewController : PlatformViewController<MTKViewDelegate>

@end
