/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The web extension handler.
*/

import SafariServices
import os.log

let SFExtensionMessageKey = "message"

class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        guard let item = context.inputItems[0] as? NSExtensionItem else { return }
        guard let message = item.userInfo?[SFExtensionMessageKey] as? CVarArg else {
            return
        }
        
        os_log(.default, "Received message from browser.runtime.sendNativeMessage: %@", message)
        let response = NSExtensionItem()
        response.userInfo = [ SFExtensionMessageKey: [ "Response to": message ] ]

        context.completeRequest(returningItems: [response], completionHandler: nil)
    }

}
