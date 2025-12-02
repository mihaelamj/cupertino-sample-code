/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file provides the app delegate for the MetalFX sample.
*/

import UIKit

@main
class AAPLAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /// The override point for customization after app launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        /// The system sends this when the app is about to move from an active state to an inactive state.
        /// This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message), or
        /// when the user quits the app and it begins the transition to the background state.
        /// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        /// Use this method to release shared resources, save user data, invalidate timers, and store enough app state
        /// information to restore your app to its current state if it terminates.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        /// The system calls this as part of the transition from the background to the active state;
        /// here you can undo many of the changes that occur on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        /// Restart any tasks that the system pauses or doesn't start while the app is inactive.
        /// If the app is previously in the background, optionally refresh the user interface.
    }
}
