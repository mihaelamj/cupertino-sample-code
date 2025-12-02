/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The component for collectable items in a game.
*/

import RealityKit

/// A component for collectable items in a game.
struct CollectableComponent: Component {
    var type: CollectableType
    enum CollectableType {
        case coin
        case key
    }
}
