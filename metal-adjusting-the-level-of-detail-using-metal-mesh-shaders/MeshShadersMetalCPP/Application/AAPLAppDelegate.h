/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform app delegate.
*/

#import <TargetConditionals.h>

#if TARGET_OS_OSX

@import AppKit;
#define PlatformAppDelegate NSObject <NSApplicationDelegate>
#define PlatformWindow      NSWindow
#define PlatformApplication NSApplication

#elif TARGET_OS_IPHONE

@import UIKit;
#define PlatformAppDelegate UIResponder <UIApplicationDelegate>
#define PlatformWindow      UIWindow
#define PlatformApplication UIApplication

#endif

@interface AAPLAppDelegate : PlatformAppDelegate

@property (strong, nonatomic) PlatformWindow* window;

@end
