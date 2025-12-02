/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The scene delegate class that supports UISplitViewControllerDelegate and open-in-place.
*/

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let window = window,
              let splitViewController = window.rootViewController as? UISplitViewController else {
            fatalError("Failed to retrieve the root split view controller. Main.storyboard may be corrupted.")
        }
        splitViewController.delegate = self
        splitViewController.preferredSplitBehavior = .tile
        splitViewController.preferredDisplayMode = .oneBesideSecondary
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let splitViewController = window?.rootViewController as? UISplitViewController,
              let navigationController = splitViewController.viewControllers.first as? UINavigationController,
              let mainViewController = navigationController.viewControllers.first as? MainViewController else {
            fatalError("Failed to retrieve the main view controller. Main.storyboard may be corrupted.")
        }
        guard let firstContext = URLContexts.first, firstContext.options.openInPlace else { return }
        
        // Apps generally need to call startAccessingSecurityScopedResource before accessing the URL because the URL
        // can be outside of their sandbox, and then call stopAccessingSecurityScopedResource after the access is complete.
        // This sample doesn't have to do that because UIDocument handles security-scoped bookmarks automatically.
        //
        mainViewController.openDocumentInPlace(url: firstContext.url)
    }
}

// MARK: - UISplitViewControllerDelegate
//
extension SceneDelegate: UISplitViewControllerDelegate {
    func splitViewController(
        _ svc: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column {
        .primary
    }
}

