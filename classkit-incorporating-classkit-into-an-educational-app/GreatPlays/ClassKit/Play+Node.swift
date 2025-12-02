/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension conforming Play to the Node protocol.
*/

import ClassKit

extension Play: Node {
    var parent: Node? {
        return nil
    }
    
    var children: [Node]? {
        return acts
    }
    
    var identifier: String {
        return title
    }
    
    var contextType: CLSContextType {
        return .book
    }
}
