/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension conforming Act to the Node protocol.
*/

import ClassKit

extension Act: Node {
    var parent: Node? {
        return play
    }
    
    var children: [Node]? {
        return scenes
    }
    
    var identifier: String {
        return "Act \(number)"
    }
    
    var contextType: CLSContextType {
        return .chapter
    }
}
