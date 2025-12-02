/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model object representing the content of the Document.
*/

import Foundation
import Cocoa

class Content: NSObject {
    @objc dynamic var contentString = ""
    
    public init(contentString: String) {
        self.contentString = contentString
    }
    
}

extension Content {
    
    func read(from data: Data) {
        contentString = String(bytes: data, encoding: .utf8)!
    }
    
    func data() -> Data? {
        return contentString.data(using: .utf8)
    }
    
}
