/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing different color picker items.
*/

import Cocoa

class ColorPickerViewController: NSViewController {
    
    let colorPickerBar = NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.colorPickerBar")
    
    static let color = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.color")
    static let text = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.text")
    static let stroke = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.stroke")
    
    @IBOutlet weak var customColors: NSButton!

    private enum PickerTypeButtonTag: Int {
        case color = 1002, text = 1003, stroke = 1004
    }
    
    private var selectedItemIdentifier: NSTouchBarItem.Identifier = color
    
    // MARK: - NSTouchBarProvider
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        
        touchBar.customizationIdentifier = colorPickerBar
        touchBar.defaultItemIdentifiers = [selectedItemIdentifier]
        touchBar.customizationAllowedItemIdentifiers = [selectedItemIdentifier]
        touchBar.principalItemIdentifier = selectedItemIdentifier
        
        return touchBar
    }
    
    // MARK: - Action Functions
    
    @IBAction func choiceAction(_ sender: AnyObject) {
        guard let button = sender as? NSButton,
            let choice = PickerTypeButtonTag(rawValue: button.tag) else { return }
        
        switch choice {
        case .color:
            selectedItemIdentifier = ColorPickerViewController.color
            
        case .text:
            selectedItemIdentifier = ColorPickerViewController.text
            
        case .stroke:
            selectedItemIdentifier = ColorPickerViewController.stroke
        }
        
        touchBar = nil
    }
    
    @IBAction func customColorsAction(_ sender: AnyObject) {
        touchBar = nil
    }
    
    @objc
    func colorDidPick(_ colorPicker: NSColorPickerTouchBarItem) {
        print("Picked color: \(colorPicker.color)")
    }
}

// MARK: - NSTouchBarDelegate

extension ColorPickerViewController: NSTouchBarDelegate {
    
    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let colorPicker: NSColorPickerTouchBarItem
        
        switch identifier {
        case ColorPickerViewController.color:
            colorPicker = NSColorPickerTouchBarItem.colorPicker(withIdentifier: identifier)
            
        case ColorPickerViewController.text:
            colorPicker = NSColorPickerTouchBarItem.textColorPicker(withIdentifier: identifier)
            
        case ColorPickerViewController.stroke:
            colorPicker = NSColorPickerTouchBarItem.strokeColorPicker(withIdentifier: identifier)
            
        default:
            return nil
        }
        
        colorPicker.customizationLabel = NSLocalizedString("Choose Photo", comment: "")
        colorPicker.target = self
        colorPicker.action = #selector(colorDidPick(_:))
        
        if customColors.state == NSControl.StateValue.on {
            let colorList = ["Red": NSColor.systemRed, "Green": NSColor.systemGreen, "Blue": NSColor.systemBlue]
            colorPicker.colorList = NSColorList()
            
            for (key, color) in colorList {
                colorPicker.colorList.setColor(color, forKey: key)
            }
        }
        
        return colorPicker
    }
    
}

