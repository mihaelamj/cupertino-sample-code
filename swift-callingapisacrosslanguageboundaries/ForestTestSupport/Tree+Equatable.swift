/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension to conform to testing protocol.
*/

import Foundation
import Forest

extension Tree: Equatable {
    static public func == (lhs: Tree, rhs: Tree) -> Bool {
        return lhs.kind == rhs.kind && lhs.name == rhs.name
    }
}
