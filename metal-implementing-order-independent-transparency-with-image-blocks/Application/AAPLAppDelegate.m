/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application's delegate.
*/

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

#if TARGET_OS_IPHONE

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

#else

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

#endif

@end
