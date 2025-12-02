/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate that handles events when the application launches.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        guard let splitViewController = window!.rootViewController as? UISplitViewController else {
            return false
        }
        
        guard let navigationController = splitViewController.viewControllers.last as? UINavigationController else {
            return false
        }
        
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        return true
    }

    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else {
            return false
        }
        
        guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else {
            return false
        }
        
        if topAsDetailController.detailItem == nil {
            return true
        }
        
        return false
    }
}
