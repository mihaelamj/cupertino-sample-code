/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements a RealityKit component to make entities run on a path.
*/

import RealityKit

/// A component that makes an entity run on a skewed line.
public struct RunAwayComponent: Component, Codable {
    /// The skew of the curve in the x-axis.
    public var curve: Float = 0.4
    /// The running speed.
    public var speed: Float = 1.0
    /// The radius of the entity to avoid overlap when running.
    public var entityRadius: Float = 1.0
    /// A flag to check whether the entity is running.
    public var isRunning = false

    public init(from decoder: any Decoder) throws {
        Self.registerSystem()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.curve = try container.decode(Float.self, forKey: .curve)
        self.entityRadius = try container.decode(Float.self, forKey: .entityRadius)
        self.speed = try container.decode(Float.self, forKey: .speed)
        self.isRunning = try container.decode(Bool.self, forKey: .isRunning)
    }

    init() {
        Self.registerSystem()
    }

    nonisolated
    private static func registerSystem() {
        Task {
            await RunAwaySystem.registerSystem()
        }
    }
}
