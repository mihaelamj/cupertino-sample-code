/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate.
*/
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // The override point for customization after app launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting
                     connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // The system calls this when creating a new scene session.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // The system calls this when the user discards a scene session.
        // If the user discards any sessions while the app isn't running, the system calls this shortly after
        // application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that are specific to the discarded scenes, because they don't return.
    }

}

