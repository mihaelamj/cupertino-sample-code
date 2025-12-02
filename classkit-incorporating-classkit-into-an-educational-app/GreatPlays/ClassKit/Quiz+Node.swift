/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension conforming Quiz to the Node protocol.
*/

import ClassKit

extension Quiz: Node {
    var parent: Node? {
        return scene
    }
    
    var children: [Node]? {
        return nil
    }
    
    var identifier: String {
        return title
    }
    
    var contextType: CLSContextType {
        return .quiz
    }
}
