/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the app delegate.
*/

#import "AAPLAppDelegate.h"

@interface AAPLAppDelegate ()

@end

@implementation AAPLAppDelegate
#if TARGET_IOS

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // The override point for customization after app launch.
    return YES;
}

#else

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication*) sender
{
    return YES;
}

#endif
@end
