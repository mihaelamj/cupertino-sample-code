/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application's main view controller.
*/

import UIKit

class MainViewController: UITableViewController, UIActionSheetDelegate {

    /// Unwind action targeted by demos that present a modal view controller, to return to the main screen.
    @IBAction func unwindToMainViewController(_ sender: UIStoryboardSegue) {
        tableView.deselectRow(at: tableView!.indexPathForSelectedRow!, animated: false)
    }
    
    // MARK: - Table view methods
	    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 8 {
            // User tapped the "Custom Back Button Titles" row that doesn't use a segue.
            
            /** Users can quickly switch between different stack levels with a tap and hold on the back button. The sample shows this
                by pushing 10 view controllers on the current navigation stack to demonstrate that back button titles are customizable
                for each view controller level in the stack.
            */
            func makeViewController(_ level: Int) -> UIViewController {
                let viewController = UIViewController()
                viewController.title = "Level \(level)"
                viewController.navigationItem.backButtonTitle = "\(level)"
                viewController.view.backgroundColor = .systemBackground
                return viewController
            }
            for level in 1..<10 {
                self.navigationController?.pushViewController(makeViewController(level), animated: false)
            }
            self.navigationController?.pushViewController(makeViewController(10), animated: true)
        }
    }

}
