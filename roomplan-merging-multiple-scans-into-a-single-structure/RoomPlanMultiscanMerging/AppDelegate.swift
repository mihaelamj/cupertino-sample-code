/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sample app's main entry point.
*/

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // The override point for customization after app launch.
        return true
    }

    // MARK: UISceneSession Life Cycle

    func application( _ application: UIApplication,
                      configurationForConnecting connectingSceneSession: UISceneSession,
                      options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when creating a new scene session.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If the user discards a session while the app isn't running,
        //  the system calls this shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that are specific to the discarded scenes. They don't return.
    }

}

