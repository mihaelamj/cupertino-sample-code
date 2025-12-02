/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This component keeps track of the axis and speed of the rotation.
*/
import RealityKit

public struct RotationComponent: Component, Codable {
    public var rotationAxis: RotationAxis = .xAxis
    public var speed: Float = 0.0

    public var axis: SIMD3<Float> {
        return rotationAxis.axis
    }
    
    public init() {}
}
