/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`LoggerWindowSceneDelegate` is the delegate for the `UIWindowScene` on the phone's display.
*/

import UIKit

class LoggerWindowSceneDelegate: NSObject, UIWindowSceneDelegate {
    
    internal var window: UIWindow?
    
    // MARK: UISceneDelegate
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene, session.configuration.name == "LoggerSceneConfiguration" else { return }
        
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        
        let loggerViewController = LoggerViewController()
        window?.rootViewController = UINavigationController(rootViewController: loggerViewController)
        window?.windowScene = windowScene
        window?.makeKeyAndVisible()
        MemoryLogger.shared.delegate = loggerViewController
        
        MemoryLogger.shared.appendEvent("Logger window scene will connect.")
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        if scene.session.configuration.name == "LoggerSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Logger window scene did disconnect.")
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene.session.configuration.name == "LoggerSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Logger window scene did become active.")
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if scene.session.configuration.name == "LoggerSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Logger window scene will resign active.")
        }
    }
}
