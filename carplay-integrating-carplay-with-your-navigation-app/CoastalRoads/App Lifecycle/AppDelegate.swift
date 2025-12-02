/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`AppDelegate` is the `UIApplicationDelegate`.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        MemoryLogger.shared.appendEvent("Application finished launching.")
        return true
    }

    // MARK: UIApplicationDelegate

    func applicationDidBecomeActive(_ application: UIApplication) {
        MemoryLogger.shared.appendEvent("Application did become active.")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        MemoryLogger.shared.appendEvent("Application will resign active.")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        MemoryLogger.shared.appendEvent("Application did enter background.")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        MemoryLogger.shared.appendEvent("Application will enter foreground.")
    }
    
}

