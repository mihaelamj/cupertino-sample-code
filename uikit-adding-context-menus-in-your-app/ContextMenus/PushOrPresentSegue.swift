/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom segue for either pushing or presenting a view controller.
*/

import UIKit

class PushOrPresentSegue: UIStoryboardSegue {
    
    override func perform() {
        let splitViewController = source.splitViewController
        
        let needsNavigationControllerForDetail = splitViewController!.traitCollection.horizontalSizeClass == .regular
        
        if needsNavigationControllerForDetail {
            let navController = UINavigationController()
            navController.viewControllers = [destination]
            let splitViewControllerVCs: [UIViewController] = splitViewController!.viewControllers
            splitViewController!.viewControllers = [splitViewControllerVCs[0], navController]
        } else {
            source.navigationController?.pushViewController(destination, animated: true)
        }
    }
    
}
