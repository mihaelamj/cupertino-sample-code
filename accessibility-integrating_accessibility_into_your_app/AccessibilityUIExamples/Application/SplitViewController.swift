/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This sample's split view managing both the main and detail view controllers.
*/

import Cocoa

class SplitViewController: NSSplitViewController, MainViewControllerDelegate {
    
    var mainViewController: MainViewController!
    var detailViewController: DetailViewController!

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Note: we keep the left split view item from growing as the window grows by setting its hugging priority to 200,
        // and the right to 199. The view with the lowest priority will be the first to take on additional width if the
        // split view grows or shrinks.
        //
        splitView.adjustSubviews()
        
        mainViewController = splitViewItems[0].viewController as? MainViewController
        mainViewController.delegate = self   // Listen for table view selection changes
        
        if let detailViewController = splitViewItems[1].viewController as? DetailViewController {
            self.detailViewController = detailViewController
        } else {
            fatalError("SplitViewController is not configured correctly.")
        }
        
        splitView.autosaveName = "SplitViewAutoSave"   // Remember the split view position.
    }

    // MARK: - MainViewControllerDelegate
    
    func didChangeExampleSelection(mainViewController: MainViewController, selection: Example?) {
        detailViewController.detailItemRecord = selection
    }
}
