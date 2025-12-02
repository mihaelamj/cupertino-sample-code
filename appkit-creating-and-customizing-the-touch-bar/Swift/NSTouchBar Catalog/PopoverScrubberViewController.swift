/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSScrubber with a NSPopoverTouchBarItem.
*/

import Cocoa

class PopoverScrubber: NSScrubber {
    var presentingItem: NSPopoverTouchBarItem?
}

// MARK: -

class PopoverScrubberViewController: NSViewController {
    
    let popoverBar = NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.popoverBar")
    let scrubberPopover = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.scrubberPopover")
    let textScrubber = NSUserInterfaceItemIdentifier("TextScrubberItemIdentifier")
    
    // MARK: - NSTouchBarProvider
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = popoverBar
        touchBar.defaultItemIdentifiers = [scrubberPopover]
        touchBar.customizationAllowedItemIdentifiers = [scrubberPopover]
        
        return touchBar
    }
}

// MARK: - NSTouchBarDelegate

extension PopoverScrubberViewController: NSTouchBarDelegate {
    
    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard identifier == scrubberPopover else { return nil }
        
        let popoverItem = NSPopoverTouchBarItem(identifier: identifier)
        popoverItem.collapsedRepresentationLabel =
            NSLocalizedString("Scrubber Popover", comment: "")
        popoverItem.customizationLabel =
            NSLocalizedString("Scrubber Popover", comment: "")
        
        let scrubber = PopoverScrubber()
        scrubber.register(NSScrubberTextItemView.self, forItemIdentifier: textScrubber)
        
        scrubber.mode = .free
        scrubber.selectionBackgroundStyle = .roundedBackground
        scrubber.delegate = self
        scrubber.dataSource = self
        scrubber.presentingItem = popoverItem
        
        popoverItem.collapsedRepresentation = scrubber
        
        popoverItem.popoverTouchBar =
            PopoverTouchBarSample(presentingItem: popoverItem)
        
        return popoverItem
    }
}

// MARK: - NSScrubberDataSource and NSScrubberDelegate

extension PopoverScrubberViewController: NSScrubberDataSource, NSScrubberDelegate {
    
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return 10
    }
    
    // Scrubber is asking for a custom view represention for a particuler item index.
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        var returnItemView = NSScrubberItemView()
        if let itemView =
            scrubber.makeItem(withIdentifier: textScrubber,
                              owner: nil) as? NSScrubberTextItemView {
            itemView.textField.stringValue = String(index)
            returnItemView = itemView
        }
        return returnItemView
    }
    
    // The user chose a particular image inside the scrubber.
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt index: Int) {
        print("\(#function) at index \(index)")
        
        if let popoverScrubber = scrubber as? PopoverScrubber,
            let popoverItem = popoverScrubber.presentingItem {
            popoverItem.showPopover(nil)
        }
    }
}

