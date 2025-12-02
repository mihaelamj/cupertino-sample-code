/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`MacWindowController` manages the application's only window.
*/

import Cocoa

class MacWindowController: NSWindowController {
    
    // The singleton window controller created from the storyboard.
    
    static var shared: MacWindowController!
    
    // Child view controllers of the root split view controller.
    
    var commandViewController: MacConfigViewController!
    var playerViewController: NSViewController!
    
    // Remember the singleton window controller when the window loads.
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Remember the singleton window controller.
        
        guard MacWindowController.shared == nil
            else { fatalError("Window controller must be a singleton") }
        
        MacWindowController.shared = self
        
        // Store references to descendant view controllers.
        
        guard let splitViewController = contentViewController as? NSSplitViewController
            else { fatalError("Root view controller must be a NSSplitViewController") }
        
        guard let commandVC = splitViewController.children[0] as? MacConfigViewController
            else { fatalError("First split child controller must be a MacConfigViewController") }
        
        commandViewController = commandVC
        playerViewController = splitViewController.children[1]
    }
    
    // Notify the configuration view controller that the data model changed.
    
    func updateConfig() {
        commandViewController.updateConfig()
    }
    
}
