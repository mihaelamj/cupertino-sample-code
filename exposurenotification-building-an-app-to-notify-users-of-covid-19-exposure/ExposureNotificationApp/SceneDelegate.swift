/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The scene delegate.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: WatermarkWindow!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        window = WatermarkWindow(windowScene: scene as! UIWindowScene)
        window.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
        (window.rootViewController as! UITabBarController).selectedIndex = 1
        window.makeKeyAndVisible()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        let rootViewController = window!.rootViewController!
        if !LocalStore.shared.isOnboarded && rootViewController.presentedViewController == nil {
            rootViewController.performSegue(withIdentifier: "ShowOnboarding", sender: nil)
        }
    }
}

class WatermarkWindow: UIWindow {
    
    let watermark = UILabel()
    
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        
        watermark.text = "REFERENCE ONLY"
        watermark.font = .boldSystemFont(ofSize: 48.0)
        watermark.textColor = .quaternaryLabel
        watermark.translatesAutoresizingMaskIntoConstraints = false
        watermark.transform = .init(rotationAngle: -.pi / 4.0)
        watermark.isAccessibilityElement = false
        addSubview(watermark)
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: watermark.centerXAnchor),
            centerYAnchor.constraint(equalTo: watermark.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)
        bringSubviewToFront(watermark)
    }
}
