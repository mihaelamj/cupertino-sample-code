/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that marks an entity as being a rock pickup.
*/

import RealityKit
public struct RockPickupComponent: Component, Codable {
    public var speechBubbleText: String = "Update the text..."
    public var speechBubbleDuration: Float = 5.0
    public var isCollected: Bool = false
    public var targetEntityId: UInt64 = 0
}
