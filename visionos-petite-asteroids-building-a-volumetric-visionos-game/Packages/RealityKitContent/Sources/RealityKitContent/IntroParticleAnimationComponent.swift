/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that holds the state for the intro particle animation system.
*/

import RealityKit

public struct IntroParticleAnimationComponent: Component, Codable {
    public var fadeIn: Bool = false
    public var fadeInTime: Float = 0
    public var maxValue: Float = 0
    public var minSpeed: Float = 0
    public var maxSpeed: Float = 0

    public init () {
    }
}
