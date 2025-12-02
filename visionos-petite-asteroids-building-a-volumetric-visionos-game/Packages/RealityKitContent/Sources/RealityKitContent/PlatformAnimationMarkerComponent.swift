/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that marks an entity as being a platform that can animate.
*/

import RealityKit

public struct PlatformAnimationMarkerComponent: Component, Codable {
    public var platformIndex = 0
    public init() {
    }
}
