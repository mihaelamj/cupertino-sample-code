/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of a window controller.
*/

import Cocoa

class WindowController: NSWindowController {
    @IBOutlet weak var toolbar: NSToolbar!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        toolbar.displayMode = .iconOnly
    }
}

extension WindowController: NSToolbarDelegate {
    func customToolbarItem(
        itemForItemIdentifier itemIdentifier: String,
        label: String,
        itemContent: AnyObject,
        target: NSViewController?,
        action: Selector) -> NSToolbarItem? {
        
        let toolbarItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier(rawValue: itemIdentifier))
        
        toolbarItem.label = label
        toolbarItem.paletteLabel = label
        toolbarItem.toolTip = label
        toolbarItem.target = target
        toolbarItem.action = action

        if let image = itemContent as? NSImage {
            toolbarItem.image = image
        } else if let view = itemContent as? NSView {
            toolbarItem.view = view
        } else {
            assertionFailure("Invalid itemContent")
        }

        return toolbarItem
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
                
        if itemIdentifier == NSToolbarItem.Identifier.fontStyleBold {
            let icon = NSImage(
                systemSymbolName: "bold",
                accessibilityDescription: NSLocalizedString("Bold", comment: "Accessibility description for bold button"))!
            return customToolbarItem(
                itemForItemIdentifier: NSToolbarItem.Identifier.fontStyleBold.rawValue,
                label: NSLocalizedString("Bold", comment: ""),
                itemContent: icon,
                target: self.contentViewController,
                action: #selector(DocumentViewController.formatBold(_:)))
        }
        
        return nil
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            NSToolbarItem.Identifier.fontStyleBold,
            NSToolbarItem.Identifier.space,
            NSToolbarItem.Identifier.writingToolsItemIdentifier
        ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [
            NSToolbarItem.Identifier.fontStyleBold,
            NSToolbarItem.Identifier.space,
            NSToolbarItem.Identifier.flexibleSpace,
            NSToolbarItem.Identifier.writingToolsItemIdentifier
        ]
    }
}

extension NSToolbarItem.Identifier {
    static let fontStyleBold: NSToolbarItem.Identifier = NSToolbarItem.Identifier(rawValue: "FontStyleBold")
}
