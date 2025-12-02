/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSCustomTouchBarItem class for images.
*/

import Cocoa

class ImageScrubberBarItemSample: NSCustomTouchBarItem, NSScrubberDelegate, NSScrubberDataSource, NSScrubberFlowLayoutDelegate {
    
    let itemViewIdentifier = NSUserInterfaceItemIdentifier("ImageItemViewIdentifier")
    
    var scrubberItemWidth: Int = 50
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(identifier: NSTouchBarItem.Identifier) {
        super.init(identifier: identifier)
        
        let scrubber = NSScrubber()
        scrubber.register(ThumbnailItemView.self, forItemIdentifier: itemViewIdentifier)
        scrubber.mode = .free
        scrubber.selectionBackgroundStyle = .roundedBackground
        scrubber.delegate = self
        scrubber.dataSource = self
        
        view = scrubber
    }
    
    private func fetchPictureResources() {
       if PhotoManager.shared.loadComplete {
            // The PhotoManager has already loaded the images.
            if let scrubber = self.view as? NSScrubber {
                scrubber.reloadData()
            }
       } else {
            // The PhotoManager hasn't loaded all the photos. This could take a while so show the progress indicator.
            PhotoManager.shared.delegate = self   // To receive a notification when the photos finish loading.
        }
    }
    
    // MARK: - NSScrubberDataSource
    
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        if PhotoManager.shared.photos.isEmpty {
            fetchPictureResources()
        }
        return PhotoManager.shared.photos.count
    }
    
    // Scrubber is asking for a custom view represention for a particuler item index.
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        var returnItemView = NSScrubberItemView()
        if let itemView =
            scrubber.makeItem(withIdentifier: itemViewIdentifier,
                              owner: nil) as? ThumbnailItemView {
            if index < PhotoManager.shared.photos.count {
                if let imageDict = PhotoManager.shared.photos[index] as? [String: Any] {
                    if let name = imageDict[PhotoManager.ImageNameKey] as? String {
                        itemView.imageName = name
                    }
                }
            }
            returnItemView = itemView
        }
        return returnItemView
    }
    
    // Scrubber is asking for the size for a particular item.
    func scrubber(_ scrubber: NSScrubber, layout: NSScrubberFlowLayout, sizeForItemAt itemIndex: Int) -> NSSize {
        return NSSize(width: scrubberItemWidth, height: 30)
    }
    
    // User chose a particular image inside the scrubber.
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt index: Int) {
        print("\(#function) at index \(index)")
    }
}

// MARK: - PhotoManagerDelegate

extension ImageScrubberBarItemSample: PhotoManagerDelegate {

    // Used to refresh the UI, when all the photos have been loaded.
    func didLoadPhotos(photos: [Any]) {
        if let scrubber = self.view as? NSScrubber {
            scrubber.reloadData()
        }
    }
    
}

