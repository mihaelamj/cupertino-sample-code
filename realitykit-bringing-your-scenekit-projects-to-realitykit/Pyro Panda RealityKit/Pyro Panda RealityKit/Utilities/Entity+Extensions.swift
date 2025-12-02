/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper extension for `Entity`.
*/

import RealityKit

internal extension Entity {
    func recursiveCall(_ action: (Entity) -> Void) {
        action(self)
        children.forEach { $0.recursiveCall(action) }
    }
}
