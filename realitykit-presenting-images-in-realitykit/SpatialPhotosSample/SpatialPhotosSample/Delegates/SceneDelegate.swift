/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The delegate class for the scene.
*/

import SwiftUI

@Observable class SceneDelegate: NSObject, UIWindowSceneDelegate {
    weak var windowScene: UIWindowScene?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            print("Unable to get the window scene in the Scene Delegate")
            return
        }
        self.windowScene = windowScene
    }
}
