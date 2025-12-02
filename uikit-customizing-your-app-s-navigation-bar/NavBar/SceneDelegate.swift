/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The scene delegate class.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property is automatically initialized and attached to the scene.
        // This delegate doesn't imply the connecting scene or session are new; see `application:configurationForConnectingSceneSession` instead.
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be recreated the next time the scene connects.
        // The scene may reconnect later, as its session wasn't necessarily discarded; see `application:didDiscardSceneSessions` instead.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene moves from an inactive state to an active state.
        // Use this method to restart any tasks paused or not yet started when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene is about to move from an active state to an inactive state.
        // This may occur due to temporary interruptions, for example, an incoming phone call.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
