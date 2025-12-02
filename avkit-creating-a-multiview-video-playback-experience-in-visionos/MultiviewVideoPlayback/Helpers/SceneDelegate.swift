/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom app and scene delegate for retrieving the `UIScene`.
*/

import UIKit

@Observable
class CustomSceneDelegate: NSObject, UIWindowSceneDelegate {
    var scene: UIScene?

    func sceneWillEnterForeground(_ scene: UIScene) {
        self.scene = scene
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        self.scene = scene
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        self.scene = nil
    }
}

class CustomApplicationDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role)

        if connectingSceneSession.role == .windowApplication {
            configuration.delegateClass = CustomSceneDelegate.self
        }

        return configuration
    }
}
