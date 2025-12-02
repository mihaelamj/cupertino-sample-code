/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The scene delegate.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard (scene as? UIWindowScene) != nil else { return }

        if let splitViewController = window?.rootViewController as? UISplitViewController {
            splitViewController.delegate = self
        }
    }
}

extension SceneDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController,
                             topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column)
        -> UISplitViewController.Column {
        // Display the primary column when the `UISplitViewController` uses the iPhone idiom.
        return .primary
    }
}
