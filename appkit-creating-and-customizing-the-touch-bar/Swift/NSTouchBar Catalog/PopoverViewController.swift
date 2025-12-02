/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSPopoverTouchBarItem.
*/

import Cocoa

class PopoverViewController: NSViewController {
    
    let popoverBar = NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.popoverBar")
    let popover = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.popover")
    
    @IBOutlet weak var useImage: NSButton!
    @IBOutlet weak var useLabel: NSButton!
    @IBOutlet weak var useCustomClose: NSButton!
    @IBOutlet weak var pressAndHold: NSButton!
    
    enum RadioButtonTag: Int {
        case imageLabel = 1014, custom = 1015
    }
    
    var representationType: RadioButtonTag = .imageLabel
    
    // MARK: - NSTouchBarProvider
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        
        touchBar.customizationIdentifier = popoverBar
        touchBar.defaultItemIdentifiers = [popover]
        touchBar.customizationAllowedItemIdentifiers = [popover]
        touchBar.principalItemIdentifier = popover
        
        return touchBar
    }
    
    // MARK: - Action Functions
    
    @IBAction func representationTypeAction(_ sender: Any) {
        guard let radioButton = sender as? NSButton,
            let choice = RadioButtonTag(rawValue: radioButton.tag) else { return }
        
        representationType = choice
        
        // Disable image and label options for custom style.
        useImage.isEnabled = representationType == .custom ? false : true
        useLabel.isEnabled = representationType == .custom ? false : true
        
        touchBar = nil
    }
    
    @IBAction func customizeAction(_ sender: Any) {
        // The user clicked the Press and Hold, or Custom Close checkboxes.
        touchBar = nil
    }
}

// MARK: - NSTouchBarDelegate

extension PopoverViewController: NSTouchBarDelegate {
    
    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard identifier == popover else { return nil }
        
        let popoverItem = NSPopoverTouchBarItem(identifier: identifier)
        popoverItem.showsCloseButton = useCustomClose.state == NSControl.StateValue.off
        popoverItem.customizationLabel = NSLocalizedString("Popover", comment: "")
        
        switch representationType {
        case .imageLabel:
            if useImage.state == NSControl.StateValue.on {
                popoverItem.collapsedRepresentationImage = NSImage(named: NSImage.bookmarksTemplateName)
            }
            
            if useLabel.state == NSControl.StateValue.on {
                popoverItem.collapsedRepresentationLabel = NSLocalizedString("Open Popover", comment: "")
            }
            
        case .custom:
            let button = NSButton(title: NSLocalizedString("Open Popover", comment: ""),
                                  target: popoverItem,
                                  action: #selector(NSPopoverTouchBarItem.showPopover(_:)))
            button.bezelColor = NSColor.systemBlue
            
            // Use the built-in gesture recognizer for tap and hold to open the popover's NSTouchBar.
            let gestureRecognizer = popoverItem.makeStandardActivatePopoverGestureRecognizer()
            button.addGestureRecognizer(gestureRecognizer)
            
            popoverItem.collapsedRepresentation = button
        }
        
        // You can set up a different NSTouchBar instance for popoverTouchBar and pressAndHoldTouchBar properties.
        // However, in that case, the chevron doesn't display. Here you just use the same NSTouchBar instance.
        if pressAndHold.state == NSControl.StateValue.on {
            popoverItem.pressAndHoldTouchBar = PopoverTouchBarSample(presentingItem: popoverItem, forPressAndHold: true)
            popoverItem.popoverTouchBar = popoverItem.pressAndHoldTouchBar!
            popoverItem.showsCloseButton = true
        } else {
            popoverItem.popoverTouchBar = PopoverTouchBarSample(presentingItem: popoverItem)
        }
        
        return popoverItem
    }
    
}

