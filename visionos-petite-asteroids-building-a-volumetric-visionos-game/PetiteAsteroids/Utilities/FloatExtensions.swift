/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Various helper functions for working with floating-point numbers.
*/

import RealityKit

public func remap(value: Float, fromRange: ClosedRange<Float>) -> Float {
    return remap(value: value, fromRange: fromRange, toRange: 0...1)
}

public func remap(value: Float, fromRange: ClosedRange<Float>, toRange: ClosedRange<Float>) -> Float {
    let remapFactor = (toRange.upperBound - toRange.lowerBound) / (fromRange.upperBound - fromRange.lowerBound)
    return toRange.lowerBound + (value - fromRange.lowerBound) * remapFactor
}

public func clampedRemap(value: Float, fromStart: Float, fromEnd: Float, toStart: Float, toEnd: Float) -> Float {
    let minBounds = toStart < toEnd ? toStart : toEnd
    let maxBounds = toEnd > toStart ? toEnd : toStart
    return simd_clamp(toStart + (value - fromStart) * (toEnd - toStart) / (fromEnd - fromStart), minBounds, maxBounds)
}

public func clamp01(_ value: Float) -> Float {
    simd_clamp(value, 0, 1)
}

public func angleBetween(from fromVector: SIMD3<Float>, to toVector: SIMD3<Float>) -> Float {
    acos(simd_clamp(dot(normalize(fromVector), normalize(toVector)), -1, 1))
}

public func signedAngleBetween(from fromVector: SIMD3<Float>, to toVector: SIMD3<Float>, axis: SIMD3<Float>) -> Float {
    let sign: Float = dot(cross(fromVector, toVector), axis) > 0 ? 1 : -1
    let angleBetween = angleBetween(from: fromVector, to: toVector)
    return angleBetween * sign
}

private func dampingFactor(smoothing: Float, deltaTime: Float) -> Float {
    smoothing == 0 ? 0 : 1 - exp2(-deltaTime / smoothing)
}

public extension Float {
    /// Perform a damped interpolation between the current value and a target value.
    mutating func lerpTo(_ targetFloat: Float, smoothing: Float, deltaTime: Float) {
        self = simd_mix(self, targetFloat, dampingFactor(smoothing: smoothing, deltaTime: deltaTime))
    }
}

public extension SIMD3<Float> {
    static let forward = SIMD3<Float>(0, 0, 1)
    
    mutating func lerpTo(_ target: SIMD3<Float>, smoothing: Float, deltaTime: Float) {
        self = mix(self, target, t: dampingFactor(smoothing: smoothing, deltaTime: deltaTime))
    }
}
