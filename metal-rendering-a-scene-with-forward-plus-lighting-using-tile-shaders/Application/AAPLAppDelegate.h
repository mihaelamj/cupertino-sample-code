/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for the application delegate
*/
#if defined(TARGET_IOS)
@import UIKit;
#define PlatformAppDelegate UIResponder <UIApplicationDelegate>
#else
@import AppKit;
#define PlatformAppDelegate NSObject<NSApplicationDelegate>
#endif

@interface AAPLAppDelegate : PlatformAppDelegate

#if defined(TARGET_IOS)
@property (strong, nonatomic) UIWindow *window;
#endif

@end
