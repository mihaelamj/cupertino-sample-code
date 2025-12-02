/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The system for following the device's position and updating the entity to move each time the scene rerenders.
*/

import RealityKit
import SwiftUI
import ARKit

/// A system that moves entities to the device's transform each time the scene rerenders.
public struct FollowSystem: System {
    static let query = EntityQuery(where: .has(FollowComponent.self))
    private let arkitSession = ARKitSession()
    private let worldTrackingProvider = WorldTrackingProvider()
    
    public init(scene: RealityKit.Scene) {
        runSession()
    }
    
    func runSession() {
        Task {
            do {
                try await arkitSession.run([worldTrackingProvider])
            } catch {
                print("Error: \(error). Head-position mode will still work.")
            }
        }
    }
    
    public func update(context: SceneUpdateContext) {
        // Check whether the world-tracking provider is running.
        guard worldTrackingProvider.state == .running else { return }
        
        // Query the device anchor at the current time.
        guard let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) else { return }
        
        // Find the transform of the device.
        let deviceTransform = Transform(matrix: deviceAnchor.originFromAnchorTransform)
    
        // Iterate through each entity in the scene containing `FollowComponent`.
        let entities = context.entities(matching: Self.query, updatingSystemWhen: .rendering)
        
        for entity in entities {
            // Move the entity to the device's transform.
            entity.move(to: deviceTransform, relativeTo: entity.parent, duration: 1.2, timingFunction: .easeInOut)
        }
    }
}
