/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform view controller.
*/

#if defined(TARGET_IOS) || defined(TARGET_TVOS)
@import UIKit;
#define PlatformViewController UIViewController
#else
@import AppKit;
#define PlatformViewController NSViewController
#endif

@import MetalKit;

#import "AAPLRenderer.h"

// The view controller.
@interface AAPLViewController : PlatformViewController

@end
