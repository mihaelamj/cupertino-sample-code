/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Plays the ending animation sequence.
*/

import Foundation
import RealityKit
import WorldCamera
import PyroPanda
import CharacterMovement
import ControllerInput
import WASDInput

extension PyroPandaView {
    func gameCompleteEvent(hero: Entity) async {

        guard let gameRoot = appModel.gameRoot,
              let door = gameRoot.findEntity(named: "door") else { return }

        stopMaxInputs(hero: hero)
        spawnFriends(gameRoot, near: [-6.0, -0.65, 2.0])

        // Unlock the door.
        gameRoot.findEntity(named: "unlock_door")?
            .components[ParticleEmitterComponent.self]?.burst()
        door.removeFromParent()

        // Run the end sequence.
        guard let gameEndFocus = appModel.gameRoot?.findEntity(named: "game_end_focus"),
              let camera = appModel.gameRoot?.findEntity(named: "camera")
        else { fatalError("Missing camera focus and world camera from scene.") }

        let orientAction = CameraOrientAction(
            transitionIn: 0.5, transitionOut: 0.5,
            azimuth: .pi / 12, elevation: .pi / 6,
            radius: 5, targetOffset: .zero, target: gameEndFocus.id
        )

        try? await Task.sleep(for: .seconds(1))

        if let orientAnim = try? AnimationResource.makeActionAnimation(
            for: orientAction, duration: Double.infinity) {
            CameraOrientActionHandler.register({ _ in CameraOrientActionHandler() })
            camera.playAnimation(orientAnim)
        }

        try? await Task.sleep(for: .seconds(1))

        // Play the congratulations sound.
        let audioAction = PlayAudioAction(audioResourceName: "musicVictory")
        if let audioAnim = try? AnimationResource.makeActionAnimation(
            for: audioAction, duration: Double.infinity) {
            self.appModel.gameAudioRoot?.playAnimation(audioAnim)
        }

        animateFriends()

        try? await Task.sleep(for: .seconds(1))

        // Show the congratulations overlay.
        appModel.levelFinished = true
    }
}
