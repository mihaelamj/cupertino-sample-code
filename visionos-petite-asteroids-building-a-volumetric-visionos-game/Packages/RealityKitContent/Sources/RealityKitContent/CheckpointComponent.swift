/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that marks an entity as being a checkpoint.
*/

import RealityKit
public struct CheckpointComponent: Component, Codable {
    public var index = 0
    public var isClaimed = false
    public init() {
    }
}
