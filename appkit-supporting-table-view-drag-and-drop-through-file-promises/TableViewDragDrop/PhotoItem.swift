/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Object representing the photo displayed.
*/

import Cocoa

// Queue for loading thumbnail images for each PhotoItem object.
var thumbNailLoaderQueue: OperationQueue = {
    let queue = OperationQueue()
    return queue
}()

protocol ThumbnailDelegate: AnyObject {
    func thumbnailDidFinish(_ photoItem: PhotoItem)
}

class PhotoItem: NSObject {

    /** Note these properties need to be declared @objc so to be
        key value coding-compliant for Cocoa Bindings in the table view storyboard.
    */
	@objc var title = NSLocalizedString("UntitledTitle", comment: "")
    @objc var image: NSImage!
	@objc var fileURL: URL!
    @objc var thumbnailImage: NSImage!
    
    private var imageLoading = false
    
    // Delegate to notify when this photo's thumbnail creation is done.
    weak var thumbnailDelegate: ThumbnailDelegate?
    
    init(url: URL) {
        fileURL = url
        do {
            // Determine the visual title for this photo to be displayed.
            let resourceValues = try fileURL.resourceValues(forKeys: Set([.localizedNameKey]))
            if let localizedName = resourceValues.localizedName {
                title = localizedName
            } else {
                // Localized name undefined, use the last path component of the URL instead.
                title = url.lastPathComponent
            }
        } catch {
            Swift.debugPrint("No localized name found for this photo.")
        }
        super.init()
    }
    
    func loadImage() {
        if image == nil && !imageLoading {
            imageLoading = true

            // Set up the async operation to create the thumbnail image.
            let loadThumbnailOperation = LoadThumbnailOperation(url: fileURL)
            
            // Set up the completion block so we know when the thumbnail image is done.
            loadThumbnailOperation.completionBlock = {
                // Finished creating the thumbnail image.
                OperationQueue.main.addOperation {
                    self.thumbnailImage = loadThumbnailOperation.thumbnailImage
                    self.imageLoading = false
                        
                    // Notify our delegate the thumbnail is ready.
                    self.thumbnailDelegate?.thumbnailDidFinish(self)
                }
            }
            // Start the async load all the photos.
            thumbNailLoaderQueue.addOperation(loadThumbnailOperation)
        }
    }
    
    class func thumbnailImageFromImage(image: NSImage, maximumSize: NSSize) -> NSImage {
        let imageSize = image.size
        let imageAspectRatio = min(maximumSize.width / imageSize.width, maximumSize.height / imageSize.height)
        let thumbnailSize = NSSize(width: imageAspectRatio * imageSize.width, height: imageAspectRatio * imageSize.height)
        let thumbnailImage = NSImage(size: thumbnailSize)
        thumbnailImage.lockFocus()
        image.draw(in: NSRect(x: 0, y: 0, width: thumbnailSize.width, height: thumbnailSize.height),
                   from: NSRect.zero,
                   operation: .sourceOver,
                   fraction: 1.0)
        thumbnailImage.unlockFocus()
        return thumbnailImage
    }
}
