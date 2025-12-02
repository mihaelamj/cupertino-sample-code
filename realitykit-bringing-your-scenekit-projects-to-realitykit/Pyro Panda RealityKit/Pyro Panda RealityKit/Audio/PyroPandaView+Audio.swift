/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The setup and extension for audio within the Pyro Panda game.
*/

import RealityKit
import CharacterMovement
import ControllerInput
import SwiftUI
import HapticUtility

extension PyroPandaView {
    func setupAudio(root: Entity, content: some RealityViewContentProtocol) {
        if let terrain = root.findEntity(named: "terrain") {
            Task {
                let ambienceAudio = try! await AudioFileResource(
                    named: "ambience.wav",
                    configuration: AudioFileResource.Configuration(
                        loadingStrategy: .stream,
                        shouldLoop: true
                    )
                )
                    terrain.playAudio(ambienceAudio)
            }
        }
        if let hero, let heroRoot = hero.findEntity(named: "Max") {
            _ = content.subscribe(to: AnimationEvents.PlaybackStarted.self, on: heroRoot, {
                try? self.characterAudioEvents(playbackController: $0.playbackController)
            })
            _ = content.subscribe(to: AnimationEvents.PlaybackLooped.self, on: heroRoot, {
                try? self.characterAudioEvents(playbackController: $0.playbackController)
            })
        }
        if let smokeRoot = root.findEntity(named: "volcano_smoke"),
           let audioLibrary = smokeRoot.components[AudioLibraryComponent.self],
           let volcanoAudio = audioLibrary.resources["volcano"] {
            smokeRoot.playAudio(volcanoAudio)
        }
    }

    func getWalkingAnimation(
        totalDuration: TimeInterval,
        targetEntity: ActionEntityResolution
    ) throws -> AnimationResource {
        let firstTwo = Array(0...9).shuffled().prefix(2)
        guard let firstName = firstTwo.first, let lastName = firstTwo.last else {
            fatalError("Could not generate random names for walking sounds")
        }

        let step1 = PlayAudioAction(targetEntity: targetEntity, audioResourceName: "step-0\(firstName)")
        let step2 = PlayAudioAction(targetEntity: targetEntity, audioResourceName: "step-0\(lastName)")

        let anim1 = try AnimationResource.makeActionAnimation(
            for: step1, duration: 0.117, delay: 0.0)
        let anim2 = try AnimationResource.makeActionAnimation(
            for: step2, duration: 0.117, delay: 0.8)

        return try AnimationResource.group(with: [anim1, anim2])
    }

    func characterAudioEvents(playbackController: AnimationPlaybackController) throws {
        guard let hero = playbackController.entity?.parent,
              let state = hero.components[CharacterStateComponent.self],
              let heroRootName = playbackController.entity?.name
        else { return }

        switch state.currentState {
        case .walking:
            // Only adding animations here for steps, due to them being a random selection.
            let walkingAnimation = try self.getWalkingAnimation(
                totalDuration: playbackController.duration,
                targetEntity: .entityNamed(heroRootName)
            )
            hero.playAnimation(walkingAnimation)
        case .spin:
            if let spinParticles = hero.findEntity(named: "CircleEmitter"),
               var particleComponent = spinParticles.components[ParticleEmitterComponent.self] {
                particleComponent.isEmitting = true
                // Add some extra circles.
                particleComponent.burst()
                spinParticles.components.remove(ParticleEmitterComponent.self)
                spinParticles.components.set(particleComponent)
            }
        case .jump:
            HapticUtility.playHapticsFile(named: "JumpUp")
        default: break
        }
    }
}

extension AnimationResource {
    func combineWithAudio(named name: String) -> AnimationResource {
        let playAudio = PlayAudioAction(audioResourceName: name, useControlledPlayback: false)

        guard let playAudioAnim = try? AnimationResource.makeActionAnimation(for: playAudio),
           let combinedAnim = try? AnimationResource.group(with: [playAudioAnim, self])
        else { return self }

        return combinedAnim
    }
}

extension Entity {
    func findAudio(named name: String) -> AudioResource? {
        self.components[AudioLibraryComponent.self]?.resources[name]
    }

    @discardableResult
    func playAudioWithAnimation(
        named name: String,
        targetEntity: ActionEntityResolution = .sourceEntity,
        delay: TimeInterval = 0.0
    ) throws -> AnimationPlaybackController {
        let audioAction = PlayAudioAction(targetEntity: targetEntity, audioResourceName: name)
        let audioAnimation = try AnimationResource.makeActionAnimation(for: audioAction, delay: delay)
        return self.playAnimation(audioAnimation)
    }
}
