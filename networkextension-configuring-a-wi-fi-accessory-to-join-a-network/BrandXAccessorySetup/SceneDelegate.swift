/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BrandXAccessorySetup SceneDelegate.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property automatically initializes and attaches” to the scene.
        // This delegate doesn't imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let windowScene = scene as? UIWindowScene {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let window = UIWindow(windowScene: windowScene)
            
            if let brandXAccessorySetQRViewController = storyBoard.instantiateViewController(identifier: "QRCode") as? SetupQRCodeViewController {
                
                let navigation = UINavigationController(rootViewController: brandXAccessorySetQRViewController)
                window.rootViewController = navigation
                
                self.window = window
                window.makeKeyAndVisible()
            }
        }
    }
    
}

