/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
NSCustomTouchBarItem for icon and text as content.
*/

import Cocoa

class IconTextScrubberBarItemSample: NSCustomTouchBarItem, NSScrubberDelegate, NSScrubberDataSource, NSScrubberFlowLayoutDelegate {
    
    let itemViewIdentifier = NSUserInterfaceItemIdentifier("TextIconItemViewIdentifier")
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(identifier: NSTouchBarItem.Identifier) {
        super.init(identifier: identifier)
        
        let scrubber = NSScrubber()
        scrubber.scrubberLayout = NSScrubberFlowLayout()
        scrubber.register(IconTextItemView.self, forItemIdentifier: itemViewIdentifier)
        scrubber.mode = .free
        scrubber.selectionBackgroundStyle = .outlineOverlay
        scrubber.delegate = self
        scrubber.dataSource = self
        
        view = scrubber
    }
    
    let testStrings = ["Alaska", "California", "New York", "Texas", "Washington", "Alaska"]
    
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return testStrings.count
    }
    
    // Scrubber is asking for a custom view represention for a particuler item index.
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        var returnItemView = NSScrubberItemView()
        if let itemView =
            scrubber.makeItem(withIdentifier: itemViewIdentifier, owner: nil) as? IconTextItemView {
            itemView.imageView.image = NSImage(named: NSImage.bookmarksTemplateName)
            itemView.textField.stringValue = testStrings[index]
            itemView.textField.sizeToFit()
            returnItemView = itemView
        }
        return returnItemView
    }
    
    // Scrubber is asking for the size for a particular item.
    func scrubber(_ scrubber: NSScrubber, layout: NSScrubberFlowLayout, sizeForItemAt itemIndex: Int) -> NSSize {
        let size = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        // Specify a system font size of 0 to automatically use the appropriate size.
        let title = testStrings[itemIndex]
        let textRect = title.boundingRect(with: size, options: [.usesFontLeading, .usesLineFragmentOrigin],
                                          attributes: [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 0)])
        //+6:  spacing.
        //+10: NSTextField horizontal padding, no good way to retrieve this though.
        var width: CGFloat = 100.0
        if let image = NSImage(named: NSImage.bookmarksTemplateName) {
            width = textRect.size.width + image.size.width + 6 + 10
        }
        
        return NSSize(width: width, height: 30)
    }
    
    // The user chose a particular image inside the scrubber.
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt index: Int) {
        print("\(#function) at index \(index)")
    }
    
}

