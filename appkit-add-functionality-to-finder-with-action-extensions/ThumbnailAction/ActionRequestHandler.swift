/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An action request handler class that creates thumbnails of passed in images.
*/

import Foundation
import Cocoa

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        // For an Action Extension there will only ever be one extension item.
        precondition(context.inputItems.count == 1)
        guard let inputItem = context.inputItems[0] as? NSExtensionItem
            else { preconditionFailure("Expected an extension item") }

        // The extension item's attachments hold the set of files to process.
        guard let inputAttachments = inputItem.attachments
            else { preconditionFailure("Expected a valid array of attachments") }
        precondition(inputAttachments.isEmpty == false, "Expected at least one attachment")

        // The output of this extension is both the existing input images and also the thumbnails.
        // Note: If the input images are not included here, they will be deleted as the action runs.
        var outputAttachments = inputAttachments

        // Use a dispatch group to synchronise asynchronous calls to loadInPlaceFileRepresentation.
        let dispatchGroup = DispatchGroup()

        for attachment in inputAttachments {
            dispatchGroup.enter()

            // Load each file, create the thumbnail to a temporary file and pass all processed thumbnails back to the operating system.
            attachment.loadInPlaceFileRepresentation(forTypeIdentifier: "public.image") { [unowned self] (url, inPlace, error) in
                // If an image can be loaded from the URL, create a thumbnail and write it to disk.
                if let sourceUrl = url {
                    let itemProvider = self.createThumbnail(sourceUrl)
                    outputAttachments.append(itemProvider)
                } else if let error = error {
                    print(error)
                } else {
                    preconditionFailure("Expected either a valid URL or an error.")
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) {
            let outputItem = NSExtensionItem()
            outputItem.attachments = outputAttachments
            context.completeRequest(returningItems: [outputItem], completionHandler: nil)
        }
    }

    /// - Tag: RegisterFileRepresentation
    fileprivate func createThumbnail(_ sourceUrl: URL) -> NSItemProvider {
        let itemProvider = NSItemProvider()
        itemProvider.registerFileRepresentation(
            forTypeIdentifier: kUTTypePNG as String, fileOptions: [.openInPlace],
            visibility: .all, loadHandler: { completionHandler in
                guard let sourceImage = NSImage(contentsOf: sourceUrl) else { return nil }
                let thumbnailImage = sourceImage.thumbnailImage
                let thumbnailUrl = self.thumbnailUrl(for: sourceUrl)
                thumbnailImage.savePNGToDisk(at: thumbnailUrl)
                completionHandler(thumbnailUrl, false, nil)
                return nil
            }
        )
        return itemProvider
    }

    /// - Tag: ItemReplacementDirectory
    func thumbnailUrl(for sourceUrl: URL) -> URL {
        do {
            let itemReplacementDirectory = try FileManager.default.url(
                for: .itemReplacementDirectory, in: .userDomainMask,
                appropriateFor: URL(fileURLWithPath: NSHomeDirectory()), create: true)
            let thumbnailFilename = sourceUrl.deletingPathExtension().lastPathComponent + " Thumbnail.png"
            return itemReplacementDirectory.appendingPathComponent(thumbnailFilename)
        } catch {
            print(error)
            preconditionFailure()
        }
    }

}
