/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The setup for all character movements in the game.
*/

import CharacterMovement
import ControllerInput
import WorldCamera
import RealityKit
import SwiftUI
import HapticUtility

extension PyroPandaView {

    func characterKeypress(keypress: KeyPress) throws {
        guard let hero else { return }
        switch keypress.key {
        case .space:
            hero.components[CharacterMovementComponent.self]?.jumpPressed = keypress.phase == .down
        case KeyEquivalent("/"):
            if let attackAnim = try? HeroAttackAction.animation(duration: 2) {
                hero.playAnimation(attackAnim)
            }
        default: break
        }
    }

    var heroCollisionFilter: CollisionFilter {
        CollisionFilter(
            group: PyroPandaCollisionGroup.player,
            mask: .all
        )
    }

    func heroMoveUpdated(
        entity: Entity,
        velocity: SIMD3<Float>,
        deltaTime: TimeInterval
    ) {
        if let controllerState = entity.components[
            CharacterControllerStateComponent.self
        ] {
            // If not on the ground, exit early.
            guard controllerState.isOnGround else { return }
        }
    }

    func controllerInputUpdater(_ component: inout ControllerInputReceiver, entity: Entity) {
        // Camera movements.
        if let camEntity = entity.scene?.findEntity(named: "camera"),
           var camComponent = camEntity.components[WorldCameraComponent.self] {
            camComponent.updateWith(joystickMotion: component.rightJoystick)
            camEntity.components.set(camComponent)
        }
        // Character movements.
        guard var characterMovement = entity.components[CharacterMovementComponent.self] else { return }

        if !characterMovement.paused {
            characterMovement.controllerDirection = [component.leftJoystick.x, 0, -component.leftJoystick.y] * 3
            if component.jumpPressed != characterMovement.jumpPressed {
                characterMovement.jumpPressed = component.jumpPressed
            }
            entity.components.set(characterMovement)
            if component.attackReady {
                component.attackReady = false
                if let attackAnim = try? HeroAttackAction.animation(duration: 1) {
                    entity.playAnimation(attackAnim)
                    HapticUtility.playHapticsFile(named: "SpinAttack")
                }
            }
        }
    }
}
