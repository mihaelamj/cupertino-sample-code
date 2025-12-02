/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary window controller for this sample.
*/

import Cocoa

/// - Tag: ItemIdentifiers
private extension NSToolbarItem.Identifier {
    static let fontSize: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "FontSize")
    static let fontStyle: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "FontStyle")
}

/// - Tag: WindowControllerClass
class WindowController: NSWindowController, NSToolbarDelegate {
    let defaultFontSize = 18
    
    /// - Tag: ToolbarOutlet
    @IBOutlet weak var toolbar: NSToolbar!
    
    /// - Tag: ItemCustomView
    // Font style toolbar item.
    @IBOutlet var styleSegmentView: NSView! // The font style changing view (ends up in an NSToolbarItem).
    
    // Font size toolbar item.
    @IBOutlet var fontSizeView: NSView! // The font size changing view (ends up in an NSToolbarItem).
    @IBOutlet var fontSizeStepper: NSStepper!
    @IBOutlet var fontSizeField: NSTextField!
    
    @objc dynamic var currentFontSize: Int = 0
    
    // MARK: - Window Controller Life Cycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        currentFontSize = defaultFontSize
        
        // Configure our toolbar (note: this can also be done in Interface Builder).
        
        /*	If you pass false here, you turn off the customization palette. The
            NSWindow method -runToolbarCustomizationPalette: handles the display
            of the palette, which you can see in Interface Builder is connected
            to the"Customize Toolbar" menu item.
         */
        toolbar.allowsUserCustomization = true
        
        /*	Tell the toolbar that it should save any toolbar configuration changes
            to user defaults, that is, persist any mode changes or item reordering.
            The app writes the configuration to the app domain using the toolbar
            identifier as the key.
         */
        toolbar.autosavesConfiguration = true
        
        // Tell the toolbar to show icons only by default.
        toolbar.displayMode = .iconOnly
        
        // Initialize our font size control here to 18-point font, and set our view controller's NSTextView to that size.
        fontSizeStepper.integerValue = Int(defaultFontSize)
        fontSizeField.stringValue = String(defaultFontSize)
        let font = NSFont(name: "Helvetica", size: CGFloat(defaultFontSize))
        contentTextView().font = font
        
        if let fontSizeTouchBarItem = touchBar!.item(forIdentifier: .popover) as? NSPopoverTouchBarItem {
            let sliderTouchBar = fontSizeTouchBarItem.popoverTouchBar
            if let sliderTouchBarItem = sliderTouchBar.item(forIdentifier: .popoverSlider) as? NSSliderTouchBarItem {
                let slider = sliderTouchBarItem.slider
                
                // Make the font size slider a bit narrowed, about 250 pixels.
                let views = ["slider": slider]
                let theConstraints =
                    NSLayoutConstraint.constraints(withVisualFormat: "H:[slider(250)]",
                                                   options: NSLayoutConstraint.FormatOptions(),
                                                   metrics: nil,
                                                   views: views)
                NSLayoutConstraint.activate(theConstraints)
                
                // Set the font size for the slider item to the same value as the stepper.
                slider.integerValue = defaultFontSize
            }
        }
    }
    
    // Convenience accessor to our NSTextView found in the content view controller.
    func contentTextView() -> NSTextView {
        let viewController = self.contentViewController as? ViewController
        return viewController!.textView
    }
   
    // MARK: - Font and Size setters
    
    func setTextViewFontSize(fontSize: Float) {
        
        fontSizeField.floatValue = round(fontSize)
        
        // Check if any text is currently selected.
        if contentTextView().selectedRange().length > 0 {
            // We have a selection, change the selected text.
            
            // Find all selection ranges.
            for range in contentTextView().selectedRanges {
                if let subRange = range as? NSRange {
                    let selectedAttrString = contentTextView().attributedString().attributedSubstring(from: subRange)
                    
                    var effectiveRange: NSRange = subRange
                    let attrs = selectedAttrString.attributes(at: 0, effectiveRange: &effectiveRange)
                    
                    if let font = attrs[NSAttributedString.Key.font] as? NSFont {
                        let newerFont = NSFontManager.shared.convert(font, toSize: CGFloat(fontSize))
                        contentTextView().setFont(newerFont, range: subRange)
                    }
                }
            }
        } else {
            // No selection, so just change the font size at insertion.
            let attrs = contentTextView().typingAttributes
            if let font = attrs[NSAttributedString.Key.font] as? NSFont {
                let newerFont = NSFontManager.shared.convert(font, toSize: CGFloat(fontSize))
                let attributesDict = [NSAttributedString.Key.font: newerFont]
                contentTextView().typingAttributes = attributesDict
            }
        }
    }
    
    // Create a newer font from a given base font, and face index from the segmented control.
    func newFontFromFaceIndex(font: NSFont, faceIndex: Int) -> NSFont {
        var newerFont = font
        switch faceIndex {
        case 0: // Plain font.
            newerFont = NSFontManager.shared.convert(newerFont, toNotHaveTrait: .italicFontMask)
            newerFont = NSFontManager.shared.convert(newerFont, toNotHaveTrait: .boldFontMask)
        case 1: // Bold font.
            newerFont = NSFontManager.shared.convert(newerFont, toNotHaveTrait: .italicFontMask)
            newerFont = NSFontManager.shared.convert(newerFont, toHaveTrait: .boldFontMask)
        case 2: // Italic font.
            newerFont = NSFontManager.shared.convert(newerFont, toNotHaveTrait: .boldFontMask)
            newerFont = NSFontManager.shared.convert(newerFont, toHaveTrait: .italicFontMask)
        default:
            debugPrint("invalid font face choice")
        }
        return newerFont
    }
    
    // This action is called to change the font style. It is called through its segmented control toolbar item.
    func setTextViewFont(index: Int) {
        // Check if any text is currently selected.
        if contentTextView().selectedRange().length > 0 {
            // We have a selection, change the selected text.
            
            // Find all selection ranges to change.
            for range in contentTextView().selectedRanges {
                if let subRange = range as? NSRange {
                    let selectedAttrString = contentTextView().attributedString().attributedSubstring(from: subRange)

                    var effectiveRange: NSRange = subRange
                    let attrs = selectedAttrString.attributes(at: 0, effectiveRange: &effectiveRange)

                    if let font = attrs[NSAttributedString.Key.font] as? NSFont {
                        let newerFont = newFontFromFaceIndex(font: font, faceIndex: index)
                        contentTextView().setFont(newerFont, range: subRange)
                    }
                }
            }
        } else {
            // No selection, so just change the font size at insertion.
            let attrs = contentTextView().typingAttributes
            if let font = attrs[NSAttributedString.Key.font] as? NSFont {
                let newerFont = newFontFromFaceIndex(font: font, faceIndex: index)
                let attributesDict = [NSAttributedString.Key.font: newerFont]
                contentTextView().typingAttributes = attributesDict
            }
        }
    }
    
    // MARK: - Action Functions
    
    /**	This action is called to change the font size.
     	It is called by the NSStepper in the toolbar item's custom view.
     */
    @IBAction func changeFontSize(_ sender: NSStepper) {
        setTextViewFontSize(fontSize: sender.floatValue)
    }
    
    /// This action is called to change the font size from the slider item found in the NSTouchBar instance.
    @IBAction func changeFontSizeBySlider(_ sender: NSSlider) {
        setTextViewFontSize(fontSize: sender.floatValue)
    }
    
    // This action is called from the change font style toolbar item and touch bar item.
    @IBAction func changeFontStyleBySegment(_ sender: NSSegmentedControl) {
        setTextViewFont(index: sender.selectedSegment)
    }
    
    /** The NSToolbarPrintItem NSToolbarItem will send the -printDocument: message to its target.
     	Since we wired its target to be ourselves in -toolbarWillAddItem:, we get called here when
     	the user tries to print by clicking the toolbar item.
     */
    @objc
    func printDocument(_ sender: AnyObject) {
        let printOperation = NSPrintOperation(view: contentTextView())
        printOperation.runModal(for: window!, delegate: nil, didRun: nil, contextInfo: nil)
    }
    
    // MARK: - NSToolbarDelegate
    
    /** Custom factory method to create NSToolbarItems.
     
     	All NSToolbarItems have a unique identifier associated with them, used to tell your
     	delegate/controller what toolbar items to initialize and return at various points.
     	Typically, for a given identifier, you need to generate a copy of your toolbar item,
     	and return. The function creates an NSToolbarItem with a bunch of NSToolbarItem parameters.
     
     	It's easy to call this function repeatedly to generate lots of NSToolbarItems for your toolbar.
     
     	The label, palettelabel, toolTip, action, and menu can all be nil, depending upon what
     	you want the item to do.
     */
    /// - Tag: CustomToolbarItem
    func customToolbarItem(
        itemForItemIdentifier itemIdentifier: String,
        label: String,
        paletteLabel: String,
        toolTip: String,
        itemContent: AnyObject) -> NSToolbarItem? {
        
        let toolbarItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier(rawValue: itemIdentifier))
        
        toolbarItem.label = label
        toolbarItem.paletteLabel = paletteLabel
        toolbarItem.toolTip = toolTip
        toolbarItem.target = self
        
        // Set the right attribute, depending on if we were given an image or a view.
        if itemContent is NSImage {
            if let image = itemContent as? NSImage {
                toolbarItem.image = image
            }
        } else if itemContent is NSView {
            if let view = itemContent as? NSView {
                toolbarItem.view = view
            }
        } else {
            assertionFailure("Invalid itemContent: object")
        }
        
        // We actually need an NSMenuItem here, so we construct one.
        let menuItem: NSMenuItem = NSMenuItem()
        menuItem.submenu = nil
        menuItem.title = label
        toolbarItem.menuFormRepresentation = menuItem
        
        return toolbarItem
    }
    
    /// - Tag: ToolbarWillAddItem
    /** This is an optional delegate function, called when a new item is about to be added to the toolbar.
     	This is a good spot to set up initial state information for toolbar items, particularly items
     	that you don't directly control yourself (like with NSToolbarPrintItemIdentifier).
     	The notification's object is the toolbar, and the "item" key in the userInfo is the toolbar item
     	being added.
     */
    func toolbarWillAddItem(_ notification: Notification) {
        let userInfo = notification.userInfo!
        if let addedItem = userInfo["item"] as? NSToolbarItem {
            let itemIdentifier = addedItem.itemIdentifier
            if itemIdentifier == .print {
                addedItem.toolTip = NSLocalizedString("print string", comment: "")
                addedItem.target = self
            }
        }
    }
    
    /**	NSToolbar delegates require this function.
     	It takes an identifier, and returns the matching NSToolbarItem. It also takes a parameter telling
     	whether this toolbar item is going into an actual toolbar, or whether it's going to be displayed
     	in a customization palette.
     */
/// - Tag: ToolbarItemForIdentifier
    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        var toolbarItem: NSToolbarItem?
        
        /** Create a new NSToolbarItem instance and set its attributes based on
            the provided item identifier.
         */
        
        if itemIdentifier == NSToolbarItem.Identifier.fontStyle {
            // 1) Font style toolbar item.
            toolbarItem =
                customToolbarItem(itemForItemIdentifier: NSToolbarItem.Identifier.fontStyle.rawValue,
                                  label: NSLocalizedString("Font Style", comment: ""),
                                  paletteLabel: NSLocalizedString("Font Style", comment: ""),
                                  toolTip: NSLocalizedString("tool tip font style", comment: ""),
                                  itemContent: styleSegmentView)!
        } else if itemIdentifier == NSToolbarItem.Identifier.fontSize {
            // 2) Font size toolbar item.
            toolbarItem =
                customToolbarItem(itemForItemIdentifier: NSToolbarItem.Identifier.fontSize.rawValue,
                                  label: NSLocalizedString("Font Size", comment: ""),
                                  paletteLabel: NSLocalizedString("Font Size", comment: ""),
                                  toolTip: NSLocalizedString("tool tip font size", comment: ""),
                                  itemContent: fontSizeView)!
        }
        
        return toolbarItem
    }
    
    /** NSToolbar delegates require this function. It returns an array holding identifiers for the default
     	set of toolbar items. It can also be called by the customization palette to display the default toolbar.
     
 		Note: That since our toolbar is defined from Interface Builder, an additional separator and customize
     	toolbar items will be automatically added to the "default" list of items.
     */
    /// - Tag: DefaultIdentifiers
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [.fontStyle, .fontSize]
    }
    
    /** NSToolbar delegates require this function. It returns an array holding identifiers for all allowed
     	toolbar items in this toolbar. Any not listed here will not be available in the customization palette.
     */
/// - Tag: AllowedToolbarItems
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [ NSToolbarItem.Identifier.fontStyle,
                 NSToolbarItem.Identifier.fontSize,
                 NSToolbarItem.Identifier.space,
                 NSToolbarItem.Identifier.flexibleSpace,
                 NSToolbarItem.Identifier.print ]
    }
}
