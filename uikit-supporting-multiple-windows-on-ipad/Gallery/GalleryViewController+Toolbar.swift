/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The toolbar portion of the main view controller that displays a collection of photos.
*/

import UIKit

#if targetEnvironment(macCatalyst)
// As a Mac Catalyst app, an 'NSToolbar' is used to inspect a photo.

extension GalleryViewController: NSToolbarDelegate {
 
    static let toolbarID = NSToolbar.Identifier("toolbarIdentifier")
    static let infoToolbarItemID = NSToolbarItem.Identifier("info")

    @objc
    func infoAction(_ sender: Any) {
        if let indexPaths = collectionView.indexPathsForSelectedItems {
            createNewScene(indexPath: indexPaths[0])
        }
    }
    
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {

        infoToolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
            
        if itemIdentifier == GalleryViewController.infoToolbarItemID {
            let barButtonItem =
                UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(infoAction(_:)))
            
            infoToolbarItem =
                InfoToolbarItem(itemIdentifier: GalleryViewController.infoToolbarItemID, barButtonItem: barButtonItem)
            infoToolbarItem.toolTip = title
            infoToolbarItem.target = self
            infoToolbarItem.autovalidates = true
            infoToolbarItem.isEnabled = false
        }
        return infoToolbarItem
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [ .flexibleSpace,
                 GalleryViewController.infoToolbarItemID ]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return [ .flexibleSpace,
                 GalleryViewController.infoToolbarItemID ]
    }
    
}

class InfoToolbarItem: NSToolbarItem {
    override func validate() { }
}

#endif // targetEnvironment(macCatalyst)
