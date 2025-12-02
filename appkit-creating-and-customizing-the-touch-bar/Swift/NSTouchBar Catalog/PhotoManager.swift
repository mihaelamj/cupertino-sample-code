/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Singlelton object for asynchronously loading all photos from the image assets.
*/

import Cocoa
import Foundation

final class PhotoManager {
    
    static let ImageNameKey = "name"
    static let ImageKey = "image"
    
    static let shared = PhotoManager()
    
    weak var delegate: PhotoManagerDelegate?
    
    var photos = [Any]()
    var loadComplete = false
    
    private init() {
        DispatchQueue.global(qos: .background).async {
            for index in 1...14 {
                let imageName = "image" + "\(index)"
                if let fullImage = NSImage(named: imageName) {
                    let imageSize = fullImage.size
                    
                    guard imageSize.width > 0 && imageSize.height > 0 else { continue }
                    
                    let thumbnailHeight: CGFloat = 30
                    let thumbnailSize = NSSize(width: ceil(thumbnailHeight * imageSize.width / imageSize.height), height: thumbnailHeight)
                    
                    DispatchQueue.main.async {
                        let thumbnail = NSImage(size: thumbnailSize)
                        thumbnail.lockFocus()
                        fullImage.draw(in: NSRect(origin: .zero, size: thumbnailSize),
                                       from: NSRect(origin: .zero, size: imageSize),
                                       operation: .sourceOver,
                                       fraction: 1.0)
                        thumbnail.unlockFocus()

                        var imageDict = [String: Any]()
                        imageDict = [PhotoManager.ImageKey: thumbnail as Any,
                                     PhotoManager.ImageNameKey: imageName]
                        self.photos.append(imageDict)
                    }
                }
            }

            self.loadComplete = true
            DispatchQueue.main.async {
                self.delegate?.didLoadPhotos(photos: self.photos)
            }
        }
    }
}

protocol PhotoManagerDelegate: AnyObject {
    func didLoadPhotos(photos: [Any])
}
