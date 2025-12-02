/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component for entities that receive input from a controller.
*/

import Foundation
import RealityKit
import GameController
import CoreHaptics

/// A component to add to an entity that receives updates from the controller.
@MainActor
public struct ControllerInputReceiver: Component {
    public var leftJoystick: SIMD2<Float> = [0, 0]
    public var rightJoystick: SIMD2<Float> = [0, 0]
    public var jumpPressed = false
    public var attackReady = false
    let update: (inout Self, Entity) -> Void
    mutating func update(for entity: Entity) {
        update(&self, entity)
    }

    public var controller: GCController? { ControllerInputSystem.controller }

    public init(update: @escaping (inout Self, Entity) -> Void) {
        Task { @MainActor in
            ControllerInputSystem.registerSystem()
        }
        self.update = update
    }
}
