/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that plays audio for the character as she rolls on the ground.
*/

import Combine
import Foundation
import RealityKit

final class CharacterAudioSystem: System {
    required init(scene: Scene) { }

    func update(context: SceneUpdateContext) {
        guard let (characterEntity, characterAudio) = context.first(withComponent: CharacterAudioComponent.self),
              let characterMovement = characterEntity.components[CharacterMovementComponent.self],
              let (_, audioResources) = context.first(withComponent: AudioResourcesComponent.self) else { return }

        characterEntity.components[CharacterAudioComponent.self]?.secondsElapsedSinceLastRoll += context.deltaTime
        
        updateRollAudio(characterEntity: characterEntity,
                        characterAudio: characterAudio,
                        characterMovement: characterMovement,
                        audioResources: audioResources)
    }
    
    @MainActor
    func updateRollAudio(characterEntity: Entity,
                         characterAudio: CharacterAudioComponent,
                         characterMovement: CharacterMovementComponent,
                         audioResources: AudioResourcesComponent ) {
        // Only play roll sounds when the rock is moving on the ground or slope.
        guard characterMovement.currentSpeed > GameSettings.playRollAudioSpeedThreshold && characterMovement.canJumpTimer > 0 else {

            // Stop any rolling sounds if the character jumps or stops.
            for controller in characterAudio.controllers {
                controller.fade(to: -.infinity, duration: 0.1)
            }

            Task { @MainActor in
                try await Task.sleep(for: .seconds(0.1))
                for controller in characterAudio.controllers {
                    controller.stop()
                }
                // Remove all audio playback controllers from storage.
                characterEntity.components[CharacterAudioComponent.self]?.controllers.removeAll()
            }
            return
        }

        let speedPercent = characterMovement.currentSpeed / GameSettings.maxMoveSpeedFor(state: .onGround)
        let intervalRange = GameSettings.rollAudioMaxInterval - GameSettings.rollAudioMinInterval
        let intervalMin = GameSettings.rollAudioMinInterval
        let interval = TimeInterval((1 - speedPercent) * intervalRange + intervalMin)

        if characterAudio.secondsElapsedSinceLastRoll >= interval {
            guard let audioResource = audioResources.get("RockRoll") else { return }
            
            // Play a rock roll sound.
            let controller = characterEntity.playAudio(audioResource)
            controller.speed = .random(in: 1...1.1)
            controller.gain = .random(in: -3...0)

            // Store the audio playback controller so that you can stop it in case the character stops
            // or jumps.
            characterEntity.components[CharacterAudioComponent.self]?.controllers.append(controller)

            // Remove audio playback controllers from storage when they finish.
            // This keeps unused controllers alive only as long as necessary.
            controller.completionHandler = { [weak controller] in
                guard let controller else { return }
                characterEntity
                    .components[CharacterAudioComponent.self]?.controllers
                    .removeAll(where: { $0 === controller })
            }

            // Reset the roll timer.
            characterEntity.components[CharacterAudioComponent.self]?.secondsElapsedSinceLastRoll = .zero
        }
    }
}
