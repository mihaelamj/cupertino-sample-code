/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Sample's main window controller.
*/

import Cocoa

class WindowController: NSWindowController {
    
    // Toolbar item to display the dropped image's size.
    @IBOutlet weak var statusToolbarItem: NSToolbarItem!
    
    // Toolbar item to add a text item to the image.
    @IBOutlet weak var addTextToolbarItem: NSToolbarItem!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        if let imageCanvasViewController = contentViewController as? ImageCanvasController {
            statusToolbarItem.view = imageCanvasViewController.imageLabel

            addTextToolbarItem.isEnabled = false
        }
    }
    
    // User click the Add Text toolbar item.
    @IBAction func addText(toolbarItem: NSToolbarItem) {
        if let imageCanvasViewController = contentViewController as? ImageCanvasController {
            imageCanvasViewController.addText(toolbarItem)
        }
    }
    
}
