/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller for the Background Window test case.
*/

import Cocoa

class BackgroundViewController: NSViewController {
    
    @IBOutlet weak var imageView: NSImageView!
    
    // Accessory view controller to hold the Set Background button as part of the window's title bar.
    var titlebarAccessoryViewController: NSTitlebarAccessoryViewController!
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        titlebarAccessoryViewController =
            storyboard?.instantiateController(withIdentifier: NSStoryboard.Name("ChangeBackground")) as? NSTitlebarAccessoryViewController
        titlebarAccessoryViewController.layoutAttribute = .bottom
        self.view.window?.addTitlebarAccessoryViewController(self.titlebarAccessoryViewController)
    }
}
