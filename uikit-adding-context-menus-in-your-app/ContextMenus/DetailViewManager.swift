/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Object for managing the split view's detail view content.
*/

import Foundation

import UIKit

extension UIViewController {

    @objc
    func popDueToSizeChange() {
        /** This view controller was pushed by the table view while in the split view controller's primary table,
            upon rotation to expand, pop this view controller (to avoid primary and detail being
            the same view controller).
        */
        if navigationController != nil {
            navigationController?.popViewController(animated: false)
        }
    }
}

class DetailViewManager: NSObject, UISplitViewControllerDelegate {
    
    // Observer of tree controller when its selection changes using KVO.
    private var viewControllersObserver: NSKeyValueObservation?
    
    var token: NSKeyValueObservation?
    
    var splitViewController: UISplitViewController! {
        didSet {
            // Set yourself as the delegate for the new split view controller (for separateSecondaryFrom).
            splitViewController.delegate = self
            
            splitViewController.preferredDisplayMode = .oneBesideSecondary
            splitViewController.presentsWithGesture = false
            
            if splitViewController.viewControllers.count > 1 {
                if let vc1 = splitViewController.viewControllers[1] as? UINavigationController {
                    vc1.topViewController?.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
                }
            }

            splitViewController.addObserver(self, forKeyPath: "viewControllers", options: .new, context: nil)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "viewControllers" {
            var newDetailViewController: UIViewController?
            let newVCs = change![NSKeyValueChangeKey.newKey] as? [UIViewController]
            if newVCs!.count > 1 {
                newDetailViewController = newVCs![1]
            }
            
            if newDetailViewController is UINavigationController {
                let navController = newDetailViewController as? UINavigationController
                newDetailViewController = navController?.topViewController
            }
            
            if newDetailViewController != nil {
                newDetailViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    func setDetailViewController(_ detailViewController: UIViewController) {
        
        var viewControllers: [UIViewController] = splitViewController.viewControllers
        
        if viewControllers.count > 1 {
            viewControllers[1] = detailViewController
        }
        
        splitViewController.viewControllers = viewControllers
        detailViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
    }
    
    // MARK: - UISplitViewControllDelegate
    
    func splitViewController(_ splitViewController: UISplitViewController,
                             separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        var returnSecondaryVC: UIViewController?
        
        if let primaryVC = primaryViewController as? UITabBarController {
            if let selectedVC = primaryVC.selectedViewController {
                if selectedVC is UINavigationController {
                    if let navVC = selectedVC as? UINavigationController {
                        let currentVC = navVC.visibleViewController
                        if (currentVC?.responds(to: #selector(UIViewController.popDueToSizeChange)))! {
                            currentVC?.popDueToSizeChange()
                        }
                        
                       returnSecondaryVC = splitViewController.storyboard?.instantiateViewController(identifier: "InitialDetail")
                    }
                }
            }
        }
        return returnSecondaryVC
    }

    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        // Return true to prevent UIKit from applying its default behavior.
        return true
    }
    
}
