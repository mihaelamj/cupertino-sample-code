/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The scene delegate.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    /**
     Apps configure their UIWindow and attach it to the provided UIWindowScene scene.

     Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.

     If using a storyboard file, as the Info.plist key `UISceneStoryboardFile` specifies,
     the window property automatically configures and attaches to the windowScene.

     Remember to retain the SceneDelegate's UIWindow.
     The recommended approach is for the SceneDelegate to retain the scene's window.
    */
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard (scene as? UIWindowScene) != nil else { return }
    }
}

