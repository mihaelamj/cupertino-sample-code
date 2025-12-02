/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller object to host the icon collection view to display contents of a folder.
*/

import Cocoa

class IconViewController: NSViewController {
    
    struct NotificationNames {
        // The notification for indicating receipt of the file system content.
        static let receivedContent = "ReceivedContentNotification"
    }

    // The key values for the icon view dictionary.
    struct IconViewKeys {
        static let keyName = "name"
        static let keyIcon = "icon"
    }
    
    @objc private dynamic var icons: [[String: Any]] = []
    
    var url: URL? {
        didSet {
            // The URL has changed, so notify yourself to update the data source.
            DispatchQueue.global(qos: .default).async {
                // Asynchronously fetch the contents of this URL.
                self.gatherContents(self.url!)
            }
        }
    }
    
    var nodeContent: Node? {
        didSet {
            // The base node has changed, so notify yourself to update the data source.
            gatherContents(nodeContent!)
        }
    }
    
    // The incoming object is the array of file system objects to display.
    private func updateIcons(_ iconArray: [[String: Any]]) {
        icons = iconArray
        
        // Notify interested view controllers when you obtain the content.
        NotificationCenter.default.post(name: Notification.Name(IconViewController.NotificationNames.receivedContent), object: nil)
    }
    
    /**	Gathering the contents and their icons might be expensive.
     	The system calls this method on a separate thread to avoid blocking the UI.
     */
    private func gatherContents(_ inObject: Any) {
        autoreleasepool {
            
            var contentArray: [[String: Any]] = []
            
            if inObject is Node {
                // You're populating the collection view from a Node.
                for node in nodeContent!.children {
                    // The node's icon has a smaller size from a previous use, and you need to make it bigger for this collection view.
                    var content: [String: Any] = [IconViewKeys.keyName: node.title]
                    
                    if let icon = node.nodeIcon.copy() as? NSImage {
                        content[IconViewKeys.keyIcon] = icon
                    }

                    contentArray.append(content)
                }
            } else {
                // You're populating the collection view from a file system directory URL.
                if let urlToDirectory = inObject as? URL {
                    do {
                        let fileURLs =
                            try FileManager.default.contentsOfDirectory(at: urlToDirectory,
                                                                        includingPropertiesForKeys: [],
                                                                        options: [])
                        for element in fileURLs {
                            // Only allow visible objects.
                            let isHidden = element.isHidden
                            if !isHidden {
                                let elementNameStr = element.localizedName
                                let elementIcon = element.icon
                                // The file system object is visible, so add it to your content array.
                                contentArray.append([
                                    IconViewKeys.keyIcon: elementIcon,
                                    IconViewKeys.keyName: elementNameStr
                                ])
                            }
                        }
                    } catch _ {}
                }
            }
            
            // Call back on the main thread to update the icons in your view.
            DispatchQueue.main.async {
                self.updateIcons(contentArray)
            }
        }
    }
    
}
