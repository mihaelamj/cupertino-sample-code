/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Helper extensions for OutlineViewController.
*/

import Cocoa
import UniformTypeIdentifiers // for UTType

extension OutlineViewController {
    
    // Returns a generic node (folder or leaf) from a specified URL.
    class func fileSystemNode(from url: URL) -> Node {
        let node = Node()
        node.url = url
        
        if url.isFolder {
            node.type = .container
        } else {
            node.type = .document
        }
        // Figure out the node's name from the URL.
        node.title = url.localizedName
        
        return node
    }
    
    // Return a Node class from the specified outline view item through its representedObject.
    class func node(from item: Any) -> Node? {
        if let treeNode = item as? NSTreeNode, let node = treeNode.representedObject as? Node {
            return node
        } else {
            return nil
        }
    }
    
}

// MARK: -

extension NSTreeController {
    
    func indexPathOfObject(anObject: Node) -> IndexPath? {
        return indexPathOfObject(anObject: anObject, nodes: self.arrangedObjects.children)
    }
    
    func indexPathOfObject(anObject: Node, nodes: [NSTreeNode]!) -> IndexPath? {
        for node in nodes {
            if anObject == node.representedObject as? Node {
                return node.indexPath
            }
            if node.children != nil {
                if let path = indexPathOfObject(anObject: anObject, nodes: node.children) {
                    return path
                }
            }
        }
        return nil
    }
}

// MARK: -

extension NSImage {
    
    // Returns the Data version of NSImage.
    func pngData() -> Data? {
        var data: Data?
        if let tiffRep = tiffRepresentation {
            if let bitmap = NSBitmapImageRep(data: tiffRep) {
                data = bitmap.representation(using: .png, properties: [:])
            }
        }
        return data
    }
}

// MARK: -

extension URL {
    
    // Returns true if this URL is a file system container (packages aren't containers).
    var isFolder: Bool {
        var isFolder = false
        if let resources = try? resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]) {
            let isURLDirectory = resources.isDirectory ?? false
            let isPackage = resources.isPackage ?? false
            isFolder = isURLDirectory && !isPackage
        }
        return isFolder
    }
    
    // Returns true if this URL points to an image file.
    var isImage: Bool {
        var isImage = false
        
        if let typeIdentifierResource = try? resourceValues(forKeys: [.typeIdentifierKey]) {
            guard let typeIdentifier = typeIdentifierResource.typeIdentifier else { return isImage }
            
            if #available(macOS 11.0, *) {
                if let utType = UTType(typeIdentifier) {
                    if utType.conforms(to: UTType.image) {
                        isImage = true // Done deducing it's an image file.
                    }
                }
            } else {
                if let imageTypes = CGImageSourceCopyTypeIdentifiers() as? [String] {
                    for imageType in imageTypes {
                        if UTTypeConformsTo(typeIdentifier as CFString, imageType as CFString) {
                            isImage = true
                            break // Done deducing it's an image file.
                        }
                    }
                }
            }
        } else {
            // Can't find the type identifier, so check further by extension.
            let imageFormats = ["jpg", "jpeg", "png", "gif", "tiff"]
            let ext = pathExtension
            isImage = imageFormats.contains(ext)
        }
        return isImage
    }
    
    // Returns the type or UTI.
    var fileType: String {
        var fileType = ""
        if let typeIdentifierResource = try? resourceValues(forKeys: [.typeIdentifierKey]) {
            fileType = typeIdentifierResource.typeIdentifier!
        }
        return fileType
    }
    
    var isHidden: Bool {
        let resource = try? resourceValues(forKeys: [.isHiddenKey])
        return (resource?.isHidden)!
    }
    
    var icon: NSImage {
        var icon: NSImage!
        if let iconValues = try? resourceValues(forKeys: [.customIconKey, .effectiveIconKey]) {
            if let customIcon = iconValues.customIcon {
                icon = customIcon
            } else if let effectiveIcon = iconValues.effectiveIcon as? NSImage {
                icon = effectiveIcon
            }
        } else {
            // Failed to not find the icon from the URL, so make a generic one.
            if #available(macOS 11.0, *) {
                let type = isFolder ? UTType.folder : UTType.image
                icon = NSWorkspace.shared.icon(for: type)
            } else {
                let osType = isFolder ? kGenericFolderIcon : kGenericDocumentIcon
                let iconType = NSFileTypeForHFSTypeCode(OSType(osType))
                icon = NSWorkspace.shared.icon(forFileType: iconType!)
            }
        }
        return icon
    }
    
    // Returns the human-visible localized name.
    var localizedName: String {
        var localizedName = ""
        if let fileNameResource = try? resourceValues(forKeys: [.localizedNameKey]) {
            localizedName = fileNameResource.localizedName!
        } else {
            // Failed to get the localized name, so use it's last path component as the name.
            localizedName = lastPathComponent
        }
        return localizedName
    }
    
    var fileSizeString: String {
        var fileSizeString = "-"
        if let allocatedSizeResource = try? resourceValues(forKeys: [.totalFileAllocatedSizeKey]) {
            if let allocatedSize = allocatedSizeResource.totalFileAllocatedSize {
                let formattedNumberStr = ByteCountFormatter.string(fromByteCount: Int64(allocatedSize), countStyle: .file)
                let fileSizeTitle = NSLocalizedString("on disk", comment: "")
                fileSizeString = String(format: fileSizeTitle, formattedNumberStr)
            }
        }
        return fileSizeString
    }

    var creationDate: Date? {
        var creationDate: Date?
       	if let fileCreationDateResource = try? resourceValues(forKeys: [.creationDateKey]) {
     		creationDate = fileCreationDateResource.creationDate
		}
        return creationDate
    }
    
    var modificationDate: Date? {
        var modificationDate: Date?
        if let modDateResource = try? resourceValues(forKeys: [.contentModificationDateKey]) {
            modificationDate = modDateResource.contentModificationDate
        }
        return modificationDate
    }
    
    // Returns the localized kind string.
    var kind: String {
        var kind = "-"
        if let kindResource = try? resourceValues(forKeys: [.localizedTypeDescriptionKey]) {
            kind = kindResource.localizedTypeDescription!
        }
        return kind
    }

}
