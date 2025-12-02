/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller to choose an overlay example.
*/

import UIKit

class PrimaryColumnTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.userInterfaceIdiom != .phone {
            // Populate the circle example to the split view detail column when both the primary and detail controllers are visible.
            performSegue(withIdentifier: "circle", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? UINavigationController,
              let mapController = destination.topViewController as? OverlayViewController,
              let identifier = segue.identifier
            else { return }
        
        mapController.currentExample = OverlayViewController.ExampleOverlay(rawValue: identifier)
    }
}

/// This is a customized segue that sets the destination controller as the secondary column in a column-based split view controller.
class SplitViewDetailSegue: UIStoryboardSegue {
    override func perform() {
        // Setting the seconday column in a modern split view controller isn't the same as
        // using the `showDetail` segue type for classic split view controllers that you configure
        // directly in Interface Builder.
        source.splitViewController?.setViewController(destination, for: .secondary)
        source.splitViewController?.show(.secondary)
    }
}
