/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Easing functions for animations.
*/

import Foundation
import RealityKit

public struct EasingFunction: Sendable {
    public static let easeInQuad = EasingFunction(evaluate: { value in value * value })
    public static let easeOutQuad = EasingFunction(evaluate: { value in 1 - (1 - value) * (1 - value) })
    public static let easeInOutQuad = EasingFunction(evaluate: { value in value < 0.5 ? 2 * value * value : 1 - pow(-2 * value + 2, 2) / 2 })
    
    public let evaluate: @Sendable (Float) -> Float
}
