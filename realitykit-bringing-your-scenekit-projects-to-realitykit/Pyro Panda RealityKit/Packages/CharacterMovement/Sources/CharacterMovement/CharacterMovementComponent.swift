/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that stores the motion information about an active playable RealityKit character.
*/

import Foundation
import RealityKit
import SwiftUI

/// A component that stores the motion information about an active playable character.
public struct CharacterMovementComponent: Component {
    /// The direction in which the WASD keys influence the character.
    public var wasdDirection: SIMD3<Float> = [0, 0, 0]
    /// The direction in which the controller buttons influence the character.
    public var controllerDirection: SIMD3<Float> = [0, 0, 0]
    /// The combined direction in which the WASD keys and the controller influence the character.
    public var combinedDirection: SIMD3<Float> { wasdDirection + controllerDirection }

    public var lastLinear: SIMD3<Float> = [0, 0, 0]

    public var orientOffset: simd_quatf = .init(angle: 90, axis: [1, 0, 0])

    /// The character wants to jump.
    public var jumpReady = false

    // A flag to pause the character movement.
    public var paused = false

    /// Someone is actively pressing the jump button.
    ///
    /// Set this value to `true` when you want the character to jump.
    public var jumpPressed = false {
        didSet {
            if jumpPressed { jumpReady = true }
        }
    }
    /// The character wants to make an attack move.
    ///
    /// Set this value to `true` when you want the character to perform an attack.
    public var attackReady = false
    public var handleKeypress: (_ key: KeyPress) throws -> Void = { _ in }
    public var characterProxy: String? // "character_model_offset"
    public init(characterProxy: String? = nil) {
        self.characterProxy = characterProxy
        Task { @MainActor in
            CharacterMovementSystem.registerSystem()
        }
    }
    /// An update callback you can use to pick up changes in the character.
    public var update: (Entity, _ velocity: SIMD3<Float>, _ deltaTime: TimeInterval) -> Void = { _, _, _  in }
}

/// A system that updates playable characters based on motion information
/// from the character movement component.
public struct CharacterMovementSystem: System {
    var gravityConstant: SIMD3<Float> { [0, -9.8, 0] * 0.04 }

    /// The default jump force for the character.
    static var jumpForce: SIMD3<Float> { [0, 0.08, 0] }

    /// The maximum speed for the character.
    let maxFlatSpeed: Float = 2.5
    var accelerationRate: Float = 0.1
    var decelerationRate: Float = 0.6

    public init(scene: RealityKit.Scene) {}

    mutating public func update(context: SceneUpdateContext) {
        let floatDeltaTime = Float(context.deltaTime)
        let movementEntities = context.entities(
            matching: EntityQuery(
                where: .has(CharacterMovementComponent.self)),
            updatingSystemWhen: .rendering
        )
        let rkCamera = realityKitCameraEntity(context: context)
        for character in movementEntities {
            guard var characterMovement = character.components[CharacterMovementComponent.self]
            else { return }

            // The character is paused, so skip this character.
            if characterMovement.paused { continue }

            let controllerInput = characterMovement.combinedDirection
            let directionLength = simd_length(controllerInput)
            var fixedDirection = if let rkCamera {
                rkCamera.orientation.flattened
                    .act(controllerInput)
            } else {
                PhysicsSimulationComponent.nearestSimulationEntity(for: character)?.orientation.flattened.inverse
                    .act(controllerInput) ?? controllerInput
            }
            fixedDirection /= 1.8
            moveCharacter(
                character, by: &fixedDirection, deltaTime: floatDeltaTime,
                lastLinear: &characterMovement.lastLinear, jump: characterMovement.jumpReady)
            reorientCharacter(character, to: fixedDirection, proxy: characterMovement.characterProxy)
            character.components[CharacterMovementComponent.self]?.lastLinear = characterMovement.lastLinear

            // Based on the controller input, change the character state.
            let targetCharacterState: CharacterStateComponent.CharacterState = if characterMovement.attackReady {
                .spin
            } else if characterMovement.jumpReady {
                .jump
            } else {
                directionLength > 1e-10 ? .walking : .idle
            }
            _ = try? CharacterStateComponent.updateState(
                for: character,
                to: targetCharacterState,
                movementSpeed: directionLength,
                childProxy: characterMovement.characterProxy
            )
            characterMovement.update(character, characterMovement.lastLinear, context.deltaTime)
        }
    }

    fileprivate func realityKitCameraEntity(context: SceneUpdateContext) -> Entity? {
        let lookupComponents: [Component.Type] = [
            PerspectiveCameraComponent.self,
            OrthographicCameraComponent.self,
            ProjectiveTransformCameraComponent.self
        ]
        for component in lookupComponents {
            let query = EntityQuery(where: .has(component))
            if let camera = context.entities(
                matching: query, updatingSystemWhen: .rendering)
                .first(where: { _ in true }) {
                return camera
            }
        }
        return nil
    }

    /// Performs character movement.
    /// - Parameters:
    ///   - character: The character to move.
    ///   - fixedDirection: The direction to move the character.
    ///   - deltaTime: The time since the last frame.
    ///   - jump: The jump flag.
    @MainActor
    fileprivate mutating func moveCharacter(
        _ character: Entity,
        by fixedDirection: inout SIMD3<Float>,
        deltaTime: Float,
        lastLinear: inout SIMD3<Float>,
        jump: Bool
    ) {
        let accelerationRate: Float = {
            let lastFlatSpeed = simd_length_squared(SIMD2<Float>(lastLinear.x, lastLinear.z))
            let newFlatSpeed = simd_length_squared(SIMD2<Float>(fixedDirection.x, fixedDirection.z))
            return lastFlatSpeed > newFlatSpeed ? self.decelerationRate : self.accelerationRate
        }()
        lastLinear.x = lastLinear.x * (1 - accelerationRate) + fixedDirection.x * deltaTime * accelerationRate
        lastLinear.z = lastLinear.z * (1 - accelerationRate) + fixedDirection.z * deltaTime * accelerationRate

        if let controllerState = character.components[CharacterControllerStateComponent.self] {
            if controllerState.isOnGround {
                lastLinear.y = jump ? CharacterMovementSystem.jumpForce.y : 0
            }
            character.components[CharacterMovementComponent.self]?.jumpReady = false
            character.components[CharacterMovementComponent.self]?.attackReady = false
         }
        // Help the character jump a bit farther by reducing the effect of gravity
        // while someone presses the jump button.
        var gravityMultiplier: Float = 1.0
        if let jumpPressed = character.components[CharacterMovementComponent.self]?.jumpPressed,
           jumpPressed {
            gravityMultiplier *= 0.4
        }
        lastLinear.y += gravityConstant.y * gravityMultiplier * deltaTime

        character.moveCharacter(by: lastLinear, deltaTime: deltaTime, relativeTo: character.parent)
    }

    @MainActor
    func reorientCharacter(_ character: Entity, to direction: SIMD3<Float>, proxy: String?) {
        var charModel: Entity = character
        if let proxy, let proxyModel = character.findEntity(named: proxy) {
            charModel = proxyModel
        }
        let orientation = simd_quatf(from: [0, 0, 1], to: normalize([direction.x, 0, direction.z]))
        if orientation.real.isNaN || orientation.angle == .zero {
            return
        }
        charModel.orientation = simd_slerp(charModel.orientation, orientation, 0.1)
    }
}
