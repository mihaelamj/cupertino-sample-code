/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Operation subclass to create a thumbnail image from a given URL.
*/

import Cocoa
import Foundation

class LoadThumbnailOperation: Operation {

    private let thumbHeight: CGFloat = 34.0
    private let thumbWidth: CGFloat = 34.0
    
    var fileURL: URL!
    var thumbnailImage: NSImage!
    
    init(url: URL) {
        fileURL = url
        super.init()
    }
    
    override var isAsynchronous: Bool { return true }
    
    override func main() {
        if  let newImage = NSImage(contentsOf: fileURL) {
            let maximumSize = NSSize(width: thumbWidth, height: thumbHeight)
            self.thumbnailImage = PhotoItem.thumbnailImageFromImage(image: newImage, maximumSize: maximumSize)
        } else {
            Swift.debugPrint("Could not allocate this image for \(String(describing: self.fileURL))")
        }
    }
    
}
