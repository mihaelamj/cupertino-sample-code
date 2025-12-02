/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the cross-platform app delegate.
*/

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

#if TARGET_IOS || TARGET_TVOS
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /// The override point for customization after app launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    /// The system sends this when the app is about to move from an active state to an inactive state.
    /// This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message), or
    /// when the user quits the app and it begins the transition to the background state.
    /// Use this method to pause ongoing tasks, disable timers, and invalidate graphics-rendering callbacks.
    /// Games can use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    /// Use this method to release shared resources, save user data, invalidate timers, and store enough app state
    /// information to restore your app to its current state if it terminates.
    /// If the app supports background execution, the system calls this method instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    /// The system calls this as part of the transition from the background to the active state.
    /// You can undo many of the changes that occur on entering the background here.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    /// Restart any tasks that the system pauses or doesn't start while the app is inactive.
    /// If the app is previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    /// The system calls this method when the app is about to terminate.
    /// Save data if appropriate.
    /// See also applicationDidEnterBackground:.
}
#else
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    /// The system calls this method for the app to initialize itself.
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    /// The system calls this method when the app is about to terminate.
    /// Save data if appropriate.
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}
#endif

@end
