/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that marks an entity as having a directional light for the fader system to fade.
*/

import RealityKit

public struct DirectionalLightFaderComponent: Component, Codable {
    public var intensity: Float = 5000

    public init() {
    }
}
