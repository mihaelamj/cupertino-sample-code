/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSButtonTouchBarItem in an NSTouchBar instance.
*/

import Cocoa

class ButtonViewController: NSViewController {
    let button = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.button")
    let buttonBar = NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.buttonBar")
    
    @IBOutlet weak var sizeConstraint: NSButton!
    @IBOutlet weak var useCustomColor: NSButton!
    
    // MARK: - Action Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = buttonBar
        touchBar.defaultItemIdentifiers = [button]
        return touchBar
    }
    
    @IBAction func customize(_ sender: AnyObject) {
        guard let touchBar = touchBar else { return }
        
        for itemIdentifier in touchBar.itemIdentifiers {
            guard let item = touchBar.item(forIdentifier: itemIdentifier) as? NSButtonTouchBarItem,
                let button = item.view as? NSButton else { continue }

            button.bezelColor = useCustomColor.state == NSControl.StateValue.on ? NSColor.systemYellow : nil
        }
    }
    
    @IBAction func buttonAction(_ sender: AnyObject) {
        if let button = sender as? NSButtonTouchBarItem {
            print("\(#function): button with title \"\(button.title)\" is tapped")
        }
    }
    
}

// MARK: - NSTouchBarDelegate

extension ButtonViewController: NSTouchBarDelegate {

    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case button:
            let buttonItem = NSButtonTouchBarItem(identifier: identifier)
            buttonItem.title = NSLocalizedString("Button", comment: "")
            buttonItem.target = self
            buttonItem.action = #selector(buttonAction)
            buttonItem.image = NSImage(systemSymbolName: "tray", accessibilityDescription: "tray")
            return buttonItem
        default:
            return nil
        }
    }

}
