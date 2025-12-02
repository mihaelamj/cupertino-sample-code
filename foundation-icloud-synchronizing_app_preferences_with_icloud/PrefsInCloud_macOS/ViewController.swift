/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for this app.
*/

import Cocoa

class ViewController: NSViewController {
   
    @IBOutlet private weak var popupButton: NSPopUpButton!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Default color background locally is "white".
        UserDefaults.standard.register(defaults: [gBackgroundColorKey: ColorIndex.white.rawValue])
        
        // Populate the popup menu with the list of known colors.
        let popupMenu = NSMenu(title: "")
        popupMenu.addItem(withTitle: ColorIndex.white.name, action: nil, keyEquivalent: "")
        popupMenu.addItem(withTitle: ColorIndex.red.name, action: nil, keyEquivalent: "")
        popupMenu.addItem(withTitle: ColorIndex.green.name, action: nil, keyEquivalent: "")
        popupMenu.addItem(withTitle: ColorIndex.yellow.name, action: nil, keyEquivalent: "")
        popupButton.menu = popupMenu
        
        prepareKeyValueStoreForUse()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Make sure we're showing the latest color as our background.
        updateUserInterface()
    }
    
    func updateUserInterface() {
        popupButton.selectItem(at: chosenColorValue)
        if let color = ColorIndex(rawValue: chosenColorValue)?.color {
            view.layer?.backgroundColor = color.cgColor
        }
    }
    
    @IBAction private func popupColorAction(_ sender: Any) {
        if let popupButton = sender as? NSPopUpButton {
            chosenColorValue = popupButton.indexOfSelectedItem
        }
    }
    
}

