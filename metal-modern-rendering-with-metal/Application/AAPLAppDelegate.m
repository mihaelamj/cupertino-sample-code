/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implemenation of tne application delegate class.
*/

#import "AAPLAppDelegate.h"

@implementation AAPLAppDelegate

#if TARGET_OS_IPHONE

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    return YES;
}

#else

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication*) sender
{
    return YES;
}

#endif

@end
