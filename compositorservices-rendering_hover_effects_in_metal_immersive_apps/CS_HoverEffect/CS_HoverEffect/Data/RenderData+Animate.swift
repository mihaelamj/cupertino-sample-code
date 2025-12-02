/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on `RenderData` that contains animation-related functions.
*/

import QuartzCore

/// Returns a value that represents a quadratic easing function.
/// - Parameter x: The input value.
func easeInOutQuad(_ x: Float) -> Float {
    return x < 0.5 ? 2 * x * x : 1 - pow(-2 * x + 2, 2) / 2
}

/// Returns a value that represents a sine easing function.
/// - Parameter x: The input value.
func easeOutSine(x: Float) -> Float {
    return sin((x * .pi) / 2)
}

/// An enumeration that describes the current state of a draw call's animation.
enum AnimationState {
    
    /// Indicates a piece that's in its original position before flying apart or after returning.
    case idle
    
    /// Indicates the piece is currently "exploding" away from its original position.
    case expanding(progress: TimeInterval)
    
    /// Indicates the piece is currently in its "exploded" location.
    case floating
    
    /// Indicates a piece that's returning to its original position after a tap.
    case contracting(progress: TimeInterval)
    
    /// Performs animation based on the current state.
    /// - Parameter deltaTime: The elapsed time since the last frame.
    mutating func animate(deltaTime: TimeInterval) {
        switch self {
        case .idle, .floating:
            break
        case .expanding(progress: let progress):
            let newProgress = progress + deltaTime / 1.0
            if newProgress > 1.0 {
                self = .floating
            } else {
                self = .expanding(progress: newProgress)
            }
        case .contracting(progress: let progress):
            let newProgress = progress + deltaTime / 1.0
            if newProgress > 1.0 {
                self = .idle
            } else {
                self = .contracting(progress: newProgress)
            }
        }
    }
    
    /// The blend factor for the transform animation.
    var transformBlend: Float {
        switch self {
        case .idle: return 0.0
        case .floating: return 1.0
        case .expanding(progress: let progress):
            return easeOutSine(x: Float(progress))
        case .contracting(progress: let progress):
            return easeInOutQuad(Float(1 - progress))
        }
    }
    
    /// A flag for whether the animation state is using a hover effect.
    var hasHover: Bool {
        switch self {
        case .floating: return true
        default:
            return false
        }
    }
}

extension RenderData {
    
    /// Performs animation based on the current state.
    func animate() async {
        let currentTime = CACurrentMediaTime()
        guard let lastRenderTime else {
            lastRenderTime = currentTime
            return
        }
        let deltaTime = currentTime - lastRenderTime
        self.lastRenderTime = currentTime
        await scene.animate(deltaTime: deltaTime)
    }
    
    /// Performs a tap for the specified draw call.
    /// - Parameter identifier: The draw call identifier.
    func tap(on identifier: UInt64) async {
        await scene.collapse(drawcallIndex: Int(identifier) - 1)
    }
}
