/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for NSTouchBarItem instances for an NSTextView.
*/

import Cocoa

class TextViewViewController: NSViewController {
    let textViewBar = NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.textViewBar")
    let toggleBold = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.toggleBold")
    
    enum ButtonTitles {
        static let normal = NSLocalizedString("Normal", comment: "")
        static let bold = NSLocalizedString("Bold", comment: "")
    }
    
    @IBOutlet weak var textView: NSTextView!
    
    @IBOutlet weak var customTouchBarCheckbox: NSButton!
    
    var isBold = false
    
    // MARK: NSTouchBarProvider
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = textViewBar
        touchBar.defaultItemIdentifiers = [toggleBold, .otherItemsProxy]
        touchBar.customizationAllowedItemIdentifiers = [toggleBold]
        touchBar.principalItemIdentifier = toggleBold
        
        return touchBar
    }
    
    // MARK: Action Functions
    
    @objc
    func toggleBoldButtonAction(_ sender: Any) {
        guard let button = sender as? NSButton else { return }
        
        isBold = !isBold
        button.title = isBold ? ButtonTitles.normal : ButtonTitles.bold
        
        if let textStorage = textView.textStorage {
            let face = isBold ? NSFontTraitMask.boldFontMask : NSFontTraitMask.unboldFontMask
            textStorage.applyFontTraits(face, range: NSRange(location: 0, length: textStorage.length))
        }
    }
    
    @IBAction func customTouchBarAction(_ sender: AnyObject) {
        textView.isAutomaticTextCompletionEnabled = customTouchBarCheckbox.state != NSControl.StateValue.on
        touchBar = nil
    }
    
}

// MARK: - NSTouchBarDelegate

extension TextViewViewController: NSTouchBarDelegate {
    
    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard identifier == toggleBold else { return nil }
        
        let custom = NSCustomTouchBarItem(identifier: identifier)
        custom.customizationLabel = NSLocalizedString("Bold Button", comment: "")
        let title = isBold ? ButtonTitles.normal : ButtonTitles.bold
        custom.view = NSButton(title: title, target: self, action: #selector(toggleBoldButtonAction(_:)))
        
        return custom
    }
    
}

// MARK: - NSTextViewDelegate

extension TextViewViewController: NSTextViewDelegate {
    func textView(_ textView: NSTextView,
                  shouldUpdateTouchBarItemIdentifiers identifiers: [NSTouchBarItem.Identifier]) -> [NSTouchBarItem.Identifier] {
        return customTouchBarCheckbox.state == NSControl.StateValue.on ? [] : identifiers
    }
    
}

