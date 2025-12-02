/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the cross-platform configuration view controller.
*/

#if defined(TARGET_IOS)
@import UIKit;
#define PlatformViewController UIViewController
#else
@import AppKit;
#define PlatformViewController NSViewController
#endif

@import MetalKit;

#include "AAPLRenderViewController.h"

@interface AAPLConfigurationViewController : PlatformViewController

@property (atomic) AAPLRenderViewController *renderViewController;

@end
