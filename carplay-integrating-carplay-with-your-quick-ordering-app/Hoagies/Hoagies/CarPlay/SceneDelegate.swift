/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods that respond to `UIWindowSceneDelegate` events for the `UIWindowScene` on the phone's display.
*/

import UIKit

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    internal var window: UIWindow?
    
    // MARK: UIWindowSceneDelegate
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let name = session.configuration.name else { return }
        MemoryLogger.shared.appendEvent("\(name) will connect.")
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        guard let name = scene.session.configuration.name else { return }
        MemoryLogger.shared.appendEvent("\(name) did disconnect.")
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let name = scene.session.configuration.name else { return }
        MemoryLogger.shared.appendEvent("\(name) did become active.")
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        guard let name = scene.session.configuration.name else { return }
        MemoryLogger.shared.appendEvent("\(name) will resign active.")
    }
}
