/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's entry point, which is the SwiftUI equivilent of `UIApplicationDelegate`.
*/

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        
        let configuration = UISceneConfiguration(
            name: "SceneConfiguration",
            sessionRole: connectingSceneSession.role)
        return configuration
    }

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

