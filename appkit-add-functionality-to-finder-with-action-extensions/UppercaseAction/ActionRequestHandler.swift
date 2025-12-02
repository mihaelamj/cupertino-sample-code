/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An action request handler class that converts text to upper case.
*/

import Foundation

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    /// - Tag: AttributedContentText
    func beginRequest(with context: NSExtensionContext) {
        // For an Action Extension there will only ever be one extension item.
        precondition(context.inputItems.count == 1)
        guard let inputItem = context.inputItems[0] as? NSExtensionItem
            else { preconditionFailure("Expected an extension item.") }

        // First, check for text content in the extension item itself. Then fall back to any
        // input attachments if none can be found. Text should be found in one of these places.
        if let inputContent = inputItem.attributedContentText {
            let outputItem = NSExtensionItem()
            outputItem.attributedContentText = NSAttributedString(string: inputContent.string.uppercased())
            context.completeRequest(returningItems: [outputItem], completionHandler: nil)
        } else if let inputAttachments = inputItem.attachments {
            // Use a dispatch group to synchronise asynchronous calls to loadObjectOfClass.
            let dispatchGroup = DispatchGroup()

            // This extension is replacing the input attachments so start with an empty array.
            var outputAttachments: [NSItemProvider] = []

            // Open the text in each attachment to upper case.
            for attachment in inputAttachments {
                dispatchGroup.enter()

                attachment.loadObject(ofClass: NSString.self as NSItemProviderReading.Type) { (object, error) in
                    if let string = object as? String {
                        let outputItemProvider = NSItemProvider(object: string.uppercased() as NSItemProviderWriting)
                        outputAttachments.append(outputItemProvider)
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: DispatchQueue.main) {
                let outputItem = NSExtensionItem()
                outputItem.attachments = outputAttachments
                context.completeRequest(returningItems: [outputItem], completionHandler: nil)
            }
        } else {
            preconditionFailure("Expected text content to be supplied.")
        }
    }

}
