/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model object representing each item in the primary table view.
*/

import UIKit

class AnyModelItem: NSObject {
    var itemID = UUID()
    var date: Date?
    var text: String?
    
    override var description: String {
        if date != nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .medium
            return dateFormatter.string(from: date!)
        } else {
            return text!
        }
    }
}

extension AnyModelItem: UIActivityItemsConfigurationReading {
    var itemProvidersForActivityItemsConfiguration: [NSItemProvider] {
        return [NSItemProvider(object: description as NSItemProviderWriting)]
    }
}
