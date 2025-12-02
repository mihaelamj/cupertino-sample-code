/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Objects that provide a scene reference to the player model.
*/

import UIKit

@Observable
class SceneProvider: NSObject, UIWindowSceneDelegate {
    var scene: UIScene? = nil
    
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

@Observable
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowApplication {
            configuration.delegateClass = SceneProvider.self
        }
        return configuration
    }
}
