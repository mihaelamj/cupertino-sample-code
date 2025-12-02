/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to NSImage that creates a thumbnail with a max size of 320 points in either dimension.
*/

import Cocoa

extension NSImage {

    public var thumbnailImage: NSImage {
        let maxDimension: CGFloat = 320
        let aspectRatio = size.width / size.height
        let thumbnailWidth = (size.width > size.height) ? maxDimension : maxDimension * aspectRatio
        let thumbnailHeight = (size.width > size.height) ? maxDimension / aspectRatio: maxDimension
        let thumbnailSize = NSSize(width: thumbnailWidth, height: thumbnailHeight)
        return NSImage(size: thumbnailSize, flipped: false, drawingHandler: { [unowned self] (rect) -> Bool in
            self.draw(in: rect)
            return true
        })
    }

}
