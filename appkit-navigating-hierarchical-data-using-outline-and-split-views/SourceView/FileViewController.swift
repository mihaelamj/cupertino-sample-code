/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller object to host the UI for file information.
*/

import Cocoa

class FileViewController: NSViewController {
    
    @IBOutlet private var fileIcon: NSImageView!
    @IBOutlet private var fileName: NSTextField!
    @IBOutlet private var fileSize: NSTextField!
    @IBOutlet private var modDate: NSTextField!
    @IBOutlet private var creationDate: NSTextField!
    @IBOutlet private var fileKindString: NSTextField!
    @IBOutlet private var fileImageView: NSImageView!
    
    @objc var url: URL? {
        // Listen for changes in the file URL.
        didSet {
            // The file icon.
            if let iconImage = url?.icon {
                iconImage.size = NSSize(width: 64, height: 64)
                fileIcon.image = iconImage
            }
            
            fileName.stringValue = url!.localizedName
            fileSize.stringValue = url!.fileSizeString
            creationDate.stringValue = (url!.creationDate != nil) ? url!.creationDate!.description : "-"
            modDate.stringValue = (url!.modificationDate != nil) ? url!.modificationDate!.description : "-"
            fileKindString.stringValue = url!.kind
            
            // Set up the image view if the URL points to an image file.
            if let image = NSImage(contentsOf: url!) {
                fileImageView.image = image
                fileImageView.isHidden = false
            } else {
                fileImageView.isHidden = true
            }
        }
    }

}

