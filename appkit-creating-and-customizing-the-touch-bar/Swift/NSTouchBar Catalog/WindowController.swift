/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main window controller for this sample.
*/

import Cocoa

class WindowController: NSWindowController {
    let label = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.label")
    let backgroundWindowIdentifier = "BackgroundWindow"
    
    var backgroundWindowController: NSWindowController!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.setFrameAutosaveName("WindowAutosave")
        
        // Load the Background Window from its separate storyboard.
        let storyboard = NSStoryboard(name: backgroundWindowIdentifier, bundle: nil)
        if let windowController =
            storyboard.instantiateController(withIdentifier: NSStoryboard.Name(backgroundWindowIdentifier))
                as? NSWindowController {
            backgroundWindowController = windowController
            backgroundWindowController.window?.setFrameAutosaveName(NSWindow.FrameAutosaveName(backgroundWindowIdentifier))
            backgroundWindowController.showWindow(nil)
        }
    }
    
    // MARK: - NSTouchBarProvider
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier =
            NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.windowTouchBar")
        touchBar.defaultItemIdentifiers = [label, .otherItemsProxy]
        return touchBar
    }
    
}

// MARK: - NSTouchBarDelegate

extension WindowController: NSTouchBarDelegate {
    
    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case label:
            let custom = NSCustomTouchBarItem(identifier: identifier)
            let label = NSTextField(labelWithString: NSLocalizedString("Catalog", comment: ""))
            custom.view = label
            return custom
        default:
            return nil
        }
    }
}

