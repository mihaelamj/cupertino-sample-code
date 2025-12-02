/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSPickerTouchBarItem in an NSTouchBar instance.
*/

import Cocoa

class PickerViewController: NSViewController {
    let picker = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.picker")
    let pickerBar = NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.pickerBar")
    
    @IBOutlet weak var singleSelection: NSButton!
    @IBOutlet weak var collapsedState: NSButton!
    @IBOutlet weak var imagesState: NSButton!
    
    // MARK: - Action Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = pickerBar
        touchBar.defaultItemIdentifiers = [picker]
        return touchBar
    }
    
    @IBAction func singleSelectionAction(_ sender: AnyObject) {
        guard let touchBar = touchBar else { return }
        
        for itemIdentifier in touchBar.itemIdentifiers {
            guard let pickerTouchBarItem = touchBar.item(forIdentifier: itemIdentifier) as? NSPickerTouchBarItem else { continue }
            
            // First reset the selection.
            pickerTouchBarItem.selectedIndex = -1
            
            pickerTouchBarItem.selectionMode = sender.state == NSControl.StateValue.on ? .selectOne : .selectAny
        }
    }
    
    @IBAction func imagesAction(_ sender: AnyObject) {
        // This creates a call to makeTouchBar.
        touchBar = nil
    }
    
    @IBAction func collapsedAction(_ sender: AnyObject) {
        guard let touchBar = touchBar else { return }
        
        for itemIdentifier in touchBar.itemIdentifiers {
            guard let pickerTouchBarItem = touchBar.item(forIdentifier: itemIdentifier) as? NSPickerTouchBarItem else { continue }
            
            pickerTouchBarItem.controlRepresentation =
                sender.state == NSControl.StateValue.on ? .collapsed : .automatic
        }
    }
    
    @objc
    func itemPicked(_ sender: AnyObject) {
        if let picker = sender as? NSPickerTouchBarItem {
            print("\(#function): picker choice \"\(picker.selectedIndex)\"")
        }
    }
}

// MARK: - NSTouchBarDelegate

extension PickerViewController: NSTouchBarDelegate {

    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case picker:
            var pickerTouchBarItem: NSPickerTouchBarItem
            
            var selectionMode: NSPickerTouchBarItem.SelectionMode = .selectAny
            if singleSelection.state == NSControl.StateValue.on {
                selectionMode = .selectOne
            }
            // You can also use:
            // selectionMode = .momentary

            if imagesState.state == NSControl.StateValue.on {
                let images = [ NSImage(systemSymbolName: "applewatch", accessibilityDescription: "Apple Watch")!,
                               NSImage(systemSymbolName: "desktopcomputer", accessibilityDescription: "iMac")!,
                               NSImage(systemSymbolName: "iphone", accessibilityDescription: "iPhone")!,
                               NSImage(systemSymbolName: "appletv", accessibilityDescription: "Apple TV")!]
                pickerTouchBarItem =
                    NSPickerTouchBarItem(identifier: identifier,
                                         images: images,
                                         selectionMode: selectionMode,
                                         target: self,
                                         action: #selector(itemPicked))
            } else {
                let labels = ["Item 1", "Item 2", "Item 3", "Item 4"]
                pickerTouchBarItem =
                    NSPickerTouchBarItem(identifier: identifier,
                                         labels: labels,
                                         selectionMode: selectionMode,
                                         target: self,
                                         action: #selector(itemPicked))
            }

            pickerTouchBarItem.selectionColor = NSColor.systemTeal
            pickerTouchBarItem.collapsedRepresentationLabel = "Choices"
            pickerTouchBarItem.controlRepresentation =
                collapsedState.state == NSControl.StateValue.on ? .collapsed : .automatic

            return pickerTouchBarItem
        default:
            return nil
        }
    }

}
