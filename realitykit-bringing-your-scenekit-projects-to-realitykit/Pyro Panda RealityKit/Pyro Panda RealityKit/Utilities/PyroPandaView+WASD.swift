/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The setup for keyboard input controls.
*/

import SwiftUI
import WASDInput
import WorldCamera
import CharacterMovement
import RealityKit

// Callbacks that `WASDInput` uses.
extension PyroPandaView {
    func onKeypress(_ keypress: KeyPress) -> KeyPress.Result {
        WASDController.shared.handleKeypress(
            keypress: keypress,
            directionalCallback: updateMovement(wasd:arrow:),
            additionalKeysCallback: additionalKeysCallback(_:)
        )

    }
    func updateMovement(wasd: SIMD2<Float>, arrow: SIMD2<Float>) {
        if appModel.levelFinished {
            hero?.components[CharacterMovementComponent.self]?.wasdDirection = .zero
            appModel.gameRoot?.findEntity(named: "camera")?.components[
                WorldCameraComponent.self
            ]?.updateWith(continuousMotion: .zero)
            return
        }

        hero?.components[CharacterMovementComponent.self]?.wasdDirection = [wasd.x, 0, wasd.y]
        appModel.gameRoot?.findEntity(named: "camera")?.components[
            WorldCameraComponent.self
        ]?.updateWith(continuousMotion: arrow)
    }

    func additionalKeysCallback(_ keypress: KeyPress) {
        if appModel.levelFinished { return }
        try? hero?.components[CharacterMovementComponent.self]?.handleKeypress(keypress)
    }
}
