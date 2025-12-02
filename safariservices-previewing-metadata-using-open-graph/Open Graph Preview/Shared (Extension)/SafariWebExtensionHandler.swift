/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The handler for the web extension.
*/

import SafariServices
import os.log

let SFExtensionMessageKey = "message"

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        if let item = context.inputItems[0] as? NSExtensionItem {
            let message = item.userInfo?[SFExtensionMessageKey]
            //swiftlint_disable force_cast
            os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@", (message as? CVarArg) ?? "nil")

            let response = NSExtensionItem()
            response.userInfo = [ SFExtensionMessageKey: [ "Response to": message ] ]

            context.completeRequest(returningItems: [response], completionHandler: nil)
        }
    }

}
