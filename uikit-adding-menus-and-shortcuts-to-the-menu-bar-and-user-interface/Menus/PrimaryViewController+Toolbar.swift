/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Toolbar support for the primary view controller.
*/

import UIKit

#if targetEnvironment(macCatalyst)

extension NSToolbarItem.Identifier {
    // Item identifiers used to create and access NSToolbarItems.
    static let addItemID = NSToolbarItem.Identifier("addIdentifier")
    static let removeItemID = NSToolbarItem.Identifier("removeIdentifier")
    static let shareItemID = NSToolbarItem.Identifier("shareIdentifier")
}

extension PrimaryViewController: NSToolbarDelegate {
 
    static let toolbarID = NSToolbar.Identifier("toolbarIdentifier")

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        var toolbarItemToAdd: NSToolbarItem?
        
        switch itemIdentifier {
        case .addItemID:
            let barButtonItem =
                UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(toolbarAddAction(_:)))
            toolbarItemToAdd = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)
            
        case .removeItemID:
            let barButtonItem =
                UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(toolbarRemoveAction(_:)))
            toolbarItemToAdd = NSToolbarItem(itemIdentifier: itemIdentifier, barButtonItem: barButtonItem)

        case .shareItemID:
            return shareItemToolbarItem
            
        default:
            toolbarItemToAdd = nil
        }

        return toolbarItemToAdd
    }
    
    func toolbarWillAddItem(_ notification: Notification) {
        let userInfo = notification.userInfo!
        if let addedToolbarItem = userInfo["item"] as? NSToolbarItem {
            let itemIdentifier = addedToolbarItem.itemIdentifier

            switch itemIdentifier {
            case .removeItemID:
                removeItemToolbarItem = addedToolbarItem
            case .addItemID:
                addItemToolbarItem = addedToolbarItem
            case .print:
                printItemToolbarItem = addedToolbarItem
            default:
                break
            }
            
            if itemIdentifier == .removeItemID {
                removeItemToolbarItem = addedToolbarItem
            } else if itemIdentifier == .addItemID {
                addItemToolbarItem = addedToolbarItem
            } else if itemIdentifier == .print {
                printItemToolbarItem = addedToolbarItem
            }
        }
    }

    func toolbarItems() -> [NSToolbarItem.Identifier] {
        var toolbarItemIdentifiers = [NSToolbarItem.Identifier]()
        if #available(macCatalyst 14.0, *) {
            toolbarItemIdentifiers.append(NSToolbarItem.Identifier.toggleSidebar)
        }
        toolbarItemIdentifiers.append(.addItemID)
        toolbarItemIdentifiers.append(.removeItemID)
        toolbarItemIdentifiers.append(.flexibleSpace)
        toolbarItemIdentifiers.append(.shareItemID)
        toolbarItemIdentifiers.append(.print)
        return toolbarItemIdentifiers
    }
    
    /** NSToolbar delegates require this function. It returns an array holding identifiers for the default
        set of toolbar items. It can also be called by the customization palette to display the default toolbar.
     */
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarItems()
    }
    
    /** NSToolbar delegates require this function. It returns an array holding identifiers for all allowed
        toolbar items in this toolbar. Any not listed here will not be available in the customization palette.
     */
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return toolbarItems()
    }

    func toolbarImage(systemName: String) -> UIImage? {
        var buttonImage: UIImage?
        if let image = UIImage(systemName: systemName) {
            if let symbol = image.applyingSymbolConfiguration(.init(pointSize: 13)) {
                let format = UIGraphicsImageRendererFormat()
                format.preferredRange = .standard
                buttonImage =
                    UIGraphicsImageRenderer(size: symbol.size, format: format).image { _ in
                        symbol.draw(at: .zero)
                    }.withRenderingMode(.alwaysTemplate)
            }
        }
        return buttonImage
    }
    
    // MARK: - Actions
    
    @objc
    func toolbarAddAction(_ sender: Any) {
        let item = AnyModelItem()
        item.date = Date()
        insert(item)
        
        // Adjust the toolbar items (in case the first table item is inserted).
        adjustToolbarItems()
    }
    
    @objc
    func toolbarRemoveAction(_ sender: Any) {
        let message = NSLocalizedString("RemoveMessage", comment: "")
        let cancelButtonTitle = NSLocalizedString("CancelTitle", comment: "")
        let destructiveButtonTitle = NSLocalizedString("RemoveTitle", comment: "")
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in }
        let destructiveAction = UIAlertAction(title: destructiveButtonTitle, style: .destructive) { _ in
            self.deleteRow()
        }
          
        // Add the OK and cancel button actions.
        alertController.addAction(destructiveAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}

#endif
