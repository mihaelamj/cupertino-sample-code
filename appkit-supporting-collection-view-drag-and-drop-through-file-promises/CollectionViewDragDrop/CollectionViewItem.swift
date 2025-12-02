/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
NSCollectionViewItem subclass that represents the photo displayed in the collection view.
*/

import Cocoa

class CollectionViewItem: NSCollectionViewItem {

    static let reuseIdentifier = NSUserInterfaceItemIdentifier("text-item-reuse-identifier")

    override var highlightState: NSCollectionViewItem.HighlightState {
        didSet {
            updateSelectionHighlighting()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateSelectionHighlighting()
        }
    }

    private func updateSelectionHighlighting() {
        if !isViewLoaded {
            return
        }

        let showAsHighlighted = (highlightState == .forSelection) ||
            (isSelected && highlightState != .forDeselection) ||
            (highlightState == .asDropTarget)

        textField?.textColor = showAsHighlighted ? .selectedControlTextColor : .labelColor
        if let box = view as? NSBox {
            box.fillColor = showAsHighlighted ? .selectedControlColor : .clear
        }
    }

}
