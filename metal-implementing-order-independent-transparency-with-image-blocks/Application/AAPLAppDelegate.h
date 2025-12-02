/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate's header.
*/

#import <TargetConditionals.h>

#if TARGET_OS_IPHONE
@import UIKit;
#define PlatformAppDelegate UIResponder <UIApplicationDelegate>
#else
#import <Cocoa/Cocoa.h>
@import AppKit;
#define PlatformAppDelegate NSObject<NSApplicationDelegate>
#endif

@interface AAPLAppDelegate : PlatformAppDelegate

#if TARGET_OS_IPHONE
@property (strong, nonatomic) UIWindow *window;
#endif

@end

