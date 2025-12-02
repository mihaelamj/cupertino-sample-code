/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component and system to use when an entity is on fire.
*/

import RealityKit
import Combine
import CharacterMovement
import Foundation
import ControllerInput
import CoreHaptics
import GameController
import HapticUtility

/// A component that signals an entity is on fire.
struct OnFireComponent: Component {
    var targetEntity: String?
    var curController: GCController?
    init(targetEntity: String? = nil) {
        self.targetEntity = targetEntity
    }
}

/// A system that updates the state of an entity when it's on fire.
struct OnFireSystem: System {
    var events: [AnyCancellable] = []
    init(scene: Scene) {
        scene.subscribe(
            to: ComponentEvents.DidAdd.self,
            componentType: OnFireComponent.self,
            didAddComponent(event:)
        ).store(in: &events)
        scene.subscribe(
            to: ComponentEvents.WillRemove.self,
            componentType: OnFireComponent.self,
            willRemoveComponent(event:)
        ).store(in: &events)
    }
    @MainActor
    func didAddComponent(event: ComponentEvents.DidAdd) {
        guard let component = event.entity.components[OnFireComponent.self] else { return }
        let target: ActionEntityResolution = if let target = component.targetEntity {
            .entityNamed(target)
        } else {
            .sourceEntity
        }
        let catchFireAction = PlayAudioAction(targetEntity: target, audioResourceName: "panda_catch_fire")
        let ouchAction = PlayAudioAction(targetEntity: target, audioResourceName: "ouch_firehit")
        event.entity.components[CharacterStateComponent.self]?.isOnFire = true
        if let catchFireAnimation = try? AnimationResource.makeActionAnimation(for: catchFireAction),
           let ouchAnimation = try? AnimationResource.makeActionAnimation(for: ouchAction, delay: 0.3),
           let combinedAnimation = try? AnimationResource.group(
            with: [catchFireAnimation, ouchAnimation]
           ) {
            event.entity.playAnimation(combinedAnimation)
        }
        if let burn = event.entity.findEntity(named: "burn") {
            burn.findEntity(named: "smoke")?
                .components[ParticleEmitterComponent.self]?.isEmitting = true
            burn.findEntity(named: "fire")?
                .components[ParticleEmitterComponent.self]?.isEmitting = true
            burn.findEntity(named: "whiteSmoke")?
                .components[ParticleEmitterComponent.self]?.isEmitting = false
        }

        // Switch `onFire` uniform to `true`.
        if let model = event.entity.findEntity(named: "max_root"),
           var modelComponent = model.components[ModelComponent.self],
           var material = modelComponent.materials.first as? ShaderGraphMaterial {
            try? material.setParameter(name: "onFire", value: .bool(true))
            modelComponent.materials[0] = material
            model.components[ModelComponent.self] = modelComponent
        }

        // Start the haptics.
        playLavaHaptics(hero: event.entity)
    }

    func willRemoveComponent(event: ComponentEvents.WillRemove) {
        guard let component = event.entity.components[OnFireComponent.self] else { return }
        let target: ActionEntityResolution = if let target = component.targetEntity {
            .entityNamed(target)
        } else {
            .sourceEntity
        }
        let aahExtinction = PlayAudioAction(targetEntity: target, audioResourceName: "aah_extinction")

        if let extinctionAudioAnimation = try? AnimationResource.makeActionAnimation(
            for: aahExtinction
        ) {
            event.entity.playAnimation(extinctionAudioAnimation)
        }

        // Switch the `onFire` uniform back.
        if let model = event.entity.findEntity(named: "max_root"),
           var modelComponent = model.components[ModelComponent.self],
           var material = modelComponent.materials.first as? ShaderGraphMaterial {
            try? material.setParameter(name: "onFire", value: .bool(false))
            modelComponent.materials[0] = material
            model.components.set(modelComponent)
        }

        if let burn = event.entity.findEntity(named: "burn") {
            burn.findEntity(named: "smoke")?.components[
                ParticleEmitterComponent.self]?.isEmitting = false
            burn.findEntity(named: "fire")?.components[
                ParticleEmitterComponent.self]?.isEmitting = false
            if let whiteSmoke = burn.findEntity(named: "whiteSmoke"),
                var whiteSmokeParticles = whiteSmoke.components[
                    ParticleEmitterComponent.self
                ] {
                // Remove and reset the particles to restart the emission.
                // These particles don't loop.
                whiteSmokeParticles.isEmitting = true
                whiteSmoke.components.remove(ParticleEmitterComponent.self)
                whiteSmoke.components.set(whiteSmokeParticles)

                // Stop emitting after 3 seconds.
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(3))
                    whiteSmokeParticles.isEmitting = false
                    whiteSmoke.components.set(whiteSmokeParticles)
                }
            }
        }

        // Stop the haptics.
        stopLavaHaptics(hero: event.entity)

        event.entity.components[CharacterStateComponent.self]?.isOnFire = false
    }

    @MainActor
    private func playLavaHaptics(hero: Entity) {
        if let inputController = hero.components[ControllerInputReceiver.self],
           var heroComponent = hero.components[HeroComponent.self] {

            if var onFireComponent = hero.components[OnFireComponent.self],
               inputController.controller != onFireComponent.curController {
                onFireComponent.curController = inputController.controller
                hero.components.set(onFireComponent)

                heroComponent.lavaHapticsPlayers = HapticUtility.patternPlayersForHapticsFile(named: "InLava")
                hero.components.set(heroComponent)
            }

            for player in heroComponent.lavaHapticsPlayers {
                try? player.start(atTime: CHHapticTimeImmediate)
            }

            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                self.playLavaHaptics(hero: hero)
            }
        }
    }

    private func stopLavaHaptics(hero: Entity) {
        if var heroComponent = hero.components[HeroComponent.self] {
            for player in heroComponent.lavaHapticsPlayers {
                try? player.stop(atTime: CHHapticTimeImmediate)
            }

            heroComponent.lavaHapticsPlayers = []
            hero.components.set(heroComponent)
        }

    }

}
