/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller for an action extension which removes opacity from passed in images with
 transparency. This extension also presents UI to the user asking what background color to
 use when making the image opaque.
*/

import Cocoa

class ActionViewController: NSViewController {

    @IBOutlet var colorPopUpButton: NSPopUpButton!

    var backgroundColor = NSColor.white
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("ActionViewController")
    }

    @IBAction func send(_ sender: AnyObject?) {
        // Get the user selected background color from the pop up button.
        backgroundColor = {
            let colors = [ NSColor.red, NSColor.green, NSColor.blue ]
            return colors[colorPopUpButton.indexOfSelectedItem]
        }()

        guard let context = extensionContext
            else { preconditionFailure("Expected an extension context") }

        // For an Action Extension there will only ever be one extension item.
        precondition(context.inputItems.count == 1)
        guard let inputItem = context.inputItems[0] as? NSExtensionItem
            else { preconditionFailure("Expected an extension item") }

        // The extension item's attachments hold the set of files to process.
        guard let inputAttachments = inputItem.attachments
            else { preconditionFailure("Expected a valid array of attachments") }
        precondition(inputAttachments.isEmpty == false, "Expected at least one attachment")

        // If the extension is replacing files in-place, do not include the input files as outputs.
        var outputAttachments: [NSItemProvider] = []

        // Use a dispatch group to synchronise asynchronous calls to loadInPlaceFileRepresentation.
        let dispatchGroup = DispatchGroup()

        for attachment in inputAttachments {
            dispatchGroup.enter()

            // Load each file, create the thumbnail to a temporary file and pass all processed thumbnails back to the operating system.
            attachment.loadInPlaceFileRepresentation(forTypeIdentifier: "public.png") { [unowned self] (url, inPlace, error) in
                // If an image can be loaded from the URL, create a thumbnail and write it to disk.
                if let url = url, let sourceImage = NSImage(contentsOf: url) {
                    let itemProvider = NSItemProvider()
                    outputAttachments.append(itemProvider)
                    itemProvider.registerFileRepresentation(forTypeIdentifier: kUTTypePNG as String,
                                                            fileOptions: [.openInPlace], visibility: .all,
                                                            loadHandler: { [unowned self] completionHandler in
                        let opaqueImage = sourceImage.opaqueImage(backgroundColor: self.backgroundColor)
                        let opaqueUrl = self.opaqueUrl(for: url)
                        opaqueImage.savePNGToDisk(at: opaqueUrl)
                        completionHandler(opaqueUrl, false, nil)
                        return nil
                    })
                } else if let error = error {
                    print(error)
                } else {
                    preconditionFailure("Expected either a valid URL or an error.")
                }

                dispatchGroup.leave()
            }
        }

        dispatchGroup.notify(queue: DispatchQueue.main) { [unowned self] in
            guard let context = self.extensionContext
                else { return }

            let outputItem = NSExtensionItem()
            outputItem.attachments = outputAttachments
            context.completeRequest(returningItems: [outputItem], completionHandler: nil)
        }
    }

    /// - Tag: CancelRequest
    @IBAction func cancel(_ sender: AnyObject?) {
        guard let context = extensionContext
            else { preconditionFailure("Expected an extension context") }
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        context.cancelRequest(withError: cancelError)
    }

    func opaqueUrl(for sourceUrl: URL) -> URL {
        do {
            let itemReplacementDirectory = try FileManager.default.url(
                for: .itemReplacementDirectory, in: .userDomainMask,
                appropriateFor: URL(fileURLWithPath: NSHomeDirectory()), create: true)
            let opaqueFilename = sourceUrl.lastPathComponent
            return itemReplacementDirectory.appendingPathComponent(opaqueFilename)
        } catch {
            print(error)
            preconditionFailure()
        }
    }

}
