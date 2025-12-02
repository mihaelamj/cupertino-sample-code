/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view controller's header.
*/

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
@import UIKit;
#define PlatformViewController UIViewController
#else
#import <Cocoa/Cocoa.h>
@import AppKit;
#define PlatformViewController NSViewController
#endif

@import MetalKit;

@interface AAPLViewController : PlatformViewController
@end

