/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The scene delegate class that Xcode generates.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard scene as? UIWindowScene != nil else { return }
    }
}

