/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension conforming Scene to the Node protocol.
*/

import ClassKit

extension Scene: Node {
    var parent: Node? {
        return act
    }
    
    var children: [Node]? {
        guard let quiz = self.quiz else { return nil }
        return [quiz]
    }
    
    var identifier: String {
        return "Scene \(number)"
    }
    
    var contextType: CLSContextType {
        return .section
    }
}
