/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A generic multiuse node object to use with NSOutlineView and NSTreeController.
*/

import Cocoa
import UniformTypeIdentifiers

enum NodeType: Int, Codable {
    case container
    case document
    case separator
    case unknown
}

/// - Tag: NodeClass
class Node: NSObject, Codable {
    var type: NodeType = .unknown
    var title: String = ""
    var identifier: String = ""
    var url: URL?
    @objc dynamic var children = [Node]()
}

extension Node {
    
    /** The tree controller calls this to determine if this node is a leaf node,
        use it to determine if the node needs a disclosure triangle.
     */
    @objc dynamic var isLeaf: Bool {
        return type == .document || type == .separator
    }
    
    var isURLNode: Bool {
        return url != nil
    }
    
    var isSpecialGroup: Bool {
        // A group node is a special node that represents either Pictures or Places as grouped sections.
        return (!isURLNode &&
            (title == OutlineViewController.NameConstants.pictures || title == OutlineViewController.NameConstants.places))
    }
    
    override class func description() -> String {
        return "Node"
    }
    
    var nodeIcon: NSImage {
        var icon = NSImage()
        if let nodeURL = url {
            // If the node has a URL, use it to obtain its icon.
            icon = nodeURL.icon
        } else {
            // There's no URL for this node, so determine its icon generically.
            if #available(macOS 11.0, *) {
                let type = isDirectory ? UTType.folder : UTType.image
                icon = NSWorkspace.shared.icon(for: type)
            } else {
                let osType = isDirectory ? kGenericFolderIcon : kGenericDocumentIcon
                let iconType = NSFileTypeForHFSTypeCode(OSType(osType))
                icon = NSWorkspace.shared.icon(forFileType: iconType!)
            }
        }
        return icon
    }
    
    var canChange: Bool {
        // You can only change (rename or add to) non-URL based directory nodes.
        return isDirectory && url == nil
    }
    
    var canAddTo: Bool {
        return isDirectory && canChange
    }
    
    var isSeparator: Bool {
        return type == .separator
    }
    
    var isDirectory: Bool {
        return type == .container
    }
    
}
