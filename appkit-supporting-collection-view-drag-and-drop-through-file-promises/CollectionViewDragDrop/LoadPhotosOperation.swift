/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Operation subclass to load all photos found in the user's Pictures directory.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType

class LoadPhotosOperation: Operation {
    var directoryURL: URL!
    var loadedImages = [PhotoItem]()
    
    override init() {
        // Load the Pictures directory URL.
        let paths = NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true)
        if let picturesFolderPath = paths.first {
            let resolvedPath = NSString(string: picturesFolderPath).resolvingSymlinksInPath
            directoryURL = URL(fileURLWithPath: resolvedPath)
        }
        super.init()
    }
    
    override var isAsynchronous: Bool { return true }
    
    override func main() {
        do {
            /** For the collection view content obtain all the image URLs
                in the Pictures folder and wrap them in PhotoItem objects.
            
                Note that this app requires sandbox read permissions to the Pictures folder, set in the app entitlements.
                Without it, error 257 will occur (no permission to view it).
            */
            let resourceValueKeys = [URLResourceKey.isRegularFileKey, URLResourceKey.typeIdentifierKey]
    
            let contents = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: resourceValueKeys,
                options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles, .skipsPackageDescendants]
            )

            if !contents.isEmpty {
                for url in contents {
                    // Make sure the url is an image file.
                    let resourceValues = try url.resourceValues(forKeys: Set([.typeIdentifierKey, URLResourceKey.isRegularFileKey]))
                    guard let isRegularFileResourceValue = resourceValues.isRegularFile else { continue }
                    guard isRegularFileResourceValue else { continue }
                    guard let fileType = resourceValues.typeIdentifier else { continue }
                    
                    if #available(macOS 11.0, *) {
                        guard let fileUTType = UTType(fileType) else { continue }
                        guard fileUTType.conforms(to: UTType.image) else { continue }
                    } else {
                        guard UTTypeConformsTo(fileType as CFString, kUTTypeImage) else { continue }
                    }
                    
                    let photoItem = PhotoItem(url: url)
                    photoItem.loadImage()
                    loadedImages.append(photoItem)
                }
            }
        } catch {
            // FileManager.default.contentsOfDirectory failed.
            Swift.debugPrint("\(error)")
        }
    }
    
}
