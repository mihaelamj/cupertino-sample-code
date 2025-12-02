/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements a RealityKit component to spin entities.
*/

import RealityKit

/// A component that spins an entity indefinitely.
public struct SpinComponent: Component, Codable {
    /// The axis to spin around in local space.
    var axis: SIMD3<Float> = [0, 1, 0]
    /// The number of full rotations to perform per second.
    var rotationsPerSecond: Float = 1

    public init(from decoder: any Decoder) throws {
        Self.registerSystem()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.axis = try container.decode(SIMD3<Float>.self, forKey: .axis)
        self.rotationsPerSecond = try container.decode(Float.self, forKey: .rotationsPerSecond)
    }

    init() {
        Self.registerSystem()
    }

    nonisolated
    private static func registerSystem() {
        Task {
            await SpinSystem.registerSystem()
        }
    }
}
