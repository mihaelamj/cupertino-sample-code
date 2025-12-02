/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that plays audio in response to notifications and events within the scene.
*/

import OSLog
import Foundation
import Combine
import RealityKit
import RealityKitContent

final class AudioCueSystem: System {

    private var subscriptions: Set<AnyCancellable> = []

    init(scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: NotificationComponent.self) {
            self.onDidAddNotificationComponent(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: GamePlayStateComponent.self) {
            self.onDidAddGamePlayState(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
    }

    @MainActor
    func onGamePlayStateUpdate(_ entity: Entity) {
        guard let gamePlayState = entity.components[GamePlayStateComponent.self],
              let scene = entity.scene,
              let ambientAudioEntity = entity.scene?.first(withComponent: AmbientAudioComponent.self)?.entity,
              let gameInfo = entity.components[GameInfoComponent.self] else {
            return
        }
        
        switch (gamePlayState, gameInfo.currentLevel) {

        case (.assetsLoaded, _):
            play(.menuMusic, entity: ambientAudioEntity, level: -6, fadeIn: .seconds(6))

        case (.introAnimation, let currentLevel):
            if entity.components[IntroAnimationConfigComponent.self]?.willStartGameWhenComplete == false {
               break
            }
            stop(.menuMusic, scene: scene, fadeOut: .seconds(3))
            if currentLevel == .main {
                play(.butteRiseMusic, entity: ambientAudioEntity, fadeIn: .seconds(0.5))
                play(.butteBottomAmbience, entity: ambientAudioEntity, fadeIn: .seconds(10))
                stopAll(scene: scene, except: [.butteRiseMusic, .butteBottomAmbience], fadeOut: .seconds(1))
            }

        case (.playing, .intro):
            play(.tutorialMusic, entity: ambientAudioEntity, level: -3, fadeIn: .seconds(6))
            stopAll(scene: scene, except: .tutorialMusic, fadeOut: .seconds(3))

        case (.playing(let isPaused), .main):
            if isPaused {
                play(.menuMusic, entity: ambientAudioEntity, level: -6, fadeIn: .seconds(6))
                stopAll(scene: scene, except: [.menuMusic, .butteBottomAmbience], fadeOut: .seconds(6))
            } else {
                play(.gameplayMusic, entity: ambientAudioEntity, level: -9, fadeIn: .seconds(4))
                stopAll(scene: scene, except: [.gameplayMusic, .butteBottomAmbience], fadeOut: .seconds(3))
            }

        case (.outroAnimation, .main):
            play(.outroMusic, entity: ambientAudioEntity, level: -1.5, fadeIn: .seconds(0.75))
            stopAll(scene: scene, except: .outroMusic, fadeOut: .seconds(3))

        case (.postGame, _):
            play(.menuMusic, entity: ambientAudioEntity, level: -3, fadeIn: .seconds(2))
            stopAll(scene: scene, except: .menuMusic, fadeOut: .seconds(3))
        default:
            break
        }
    }

    @MainActor
    func play(_ cue: AudioCue, entity: Entity, level: Audio.Decibel = .zero, fadeIn: Duration = .zero) {
        // Get the audio cue storage from somewhere in the entity's ascendant entities.
        guard let (audioCueStorageEntity, audioCueStorage) = entity.firstParent(withComponent: AudioCueStorageComponent.self) else {
            return
        }
        
        // If a controller already exists for this cue, fade it to the desired level and then return early.
        if let controller = audioCueStorage.controllers[cue] {
            controller.fade(to: level, duration: fadeIn.seconds)
            return
        }
        
        guard let scene = entity.scene else {
            logger.error("Can't play audio cue, entity has no scene.")
            return
        }

        guard let resources = scene.first(withComponent: AudioResourcesComponent.self)?.component else {
            logger.error("Can't play audio cue '\(cue.resourceName)'. Audio resources have not completed loading yet. ")
            return
        }

        guard let resource = resources.get(cue.resourceName) else {
            logger.error("Can't play audio cue '\(cue.resourceName)'. No resource found.")
            return
        }

        // Receive an audio playback controller by playing audio on the entity.
        let controller = entity.playAudio(resource)
        controller.gain = -.infinity
        controller.fade(to: level, duration: fadeIn.seconds)
        
        // Store the controller in the audio cue storage component.
        audioCueStorageEntity.components[AudioCueStorageComponent.self]?.controllers[cue] = controller

        // Remove the controller from storage when audio playback completes.
        controller.completionHandler = { [weak self] in
            guard self != nil else { return }
            audioCueStorageEntity.components[AudioCueStorageComponent.self]?.controllers[cue] = nil
        }
    }

    /// Stop a specific audio cue if it's playing in the scene.
    @MainActor
    func stop(_ cue: AudioCue, scene: Scene, fadeOut: Duration = .zero) {
        // Get the audio cue storage from somewhere in the entity's ascendant entities.
        guard let (audioCueStorageEntity, audioCueStorage) = scene.first(withComponent: AudioCueStorageComponent.self),
              let controller = audioCueStorage.controllers[cue] else {
            return
        }

        controller.fade(to: -.infinity, duration: fadeOut.seconds)

        Task { @MainActor in
            try await Task.sleep(for: fadeOut)
            controller.stop()
            audioCueStorageEntity.components[AudioCueStorageComponent.self]?.controllers[cue] = nil
        }
    }

    /// Stop all audio cues in the scene except the desired audio cues.
    @MainActor
    func stopAll(scene: Scene, except cues: Set<AudioCue> = [], fadeOut: Duration = .zero ) {
        for otherCue in Set(AudioCue.allCases).subtracting(cues) {
            stop(otherCue, scene: scene, fadeOut: fadeOut)
        }
    }

    /// Stop all audio cues in the scene except the desired audio cue.
    @MainActor
    func stopAll(scene: Scene, except cue: AudioCue, fadeOut: Duration = .zero) {
        stopAll(scene: scene, except: [cue], fadeOut: fadeOut)
    }

    @MainActor
    func onDidAddGamePlayState(event: ComponentEvents.DidAdd) {
        onGamePlayStateUpdate(event.entity)
    }

    @MainActor
    func onDidChangeGamePlayState(event: ComponentEvents.DidChange) {
        onGamePlayStateUpdate(event.entity)
    }

    @MainActor
    func onDidAddNotificationComponent(event: ComponentEvents.DidAdd) {
        guard let notification = event.entity.components[NotificationComponent.self],
              let ambientAudioEntity = event.entity.scene?.first(withComponent: AmbientAudioComponent.self)?.entity,
              let scene = event.entity.scene else {
            return
        }
        
        let rock = scene.findEntity(named: "TutorialIntro")
        switch notification.name {
        case "FieryDescent":
            play(.fieryDescentSky, entity: ambientAudioEntity, level: -3, fadeIn: .seconds(8))
            play(.fieryDescentSFXAmbient, entity: ambientAudioEntity, fadeIn: .seconds(9))
            if let (particleEffects, _) = scene.first(withComponent: IntroParticleAnimationComponent.self) {
                play(.fieryDescentSFXSpatial, entity: particleEffects, fadeIn: .seconds(8))
            }
            stopAll(scene: scene, except: [.fieryDescentSky, .fieryDescentSFXAmbient, .fieryDescentSFXSpatial], fadeOut: .seconds(6))
        case "CrashAudio1":
            stopAll(scene: scene)
            rock?.components.set(AudioEventComponent(resourceName: "Crash1"))
            ambientAudioEntity.components.set(AudioEventComponent(resourceName: "Crash_Ambient"))
        case "CrashAudio2":
            rock?.components.set(AudioEventComponent(resourceName: "RockDrop", volumePercent: 0.5))
        case "CrashAudio3":
            rock?.components.set(AudioEventComponent(resourceName: "RockDrop", volumePercent: 0.25))
        case "CrashAudio4":
            rock?.components.set(AudioEventComponent(resourceName: "RockDrop", volumePercent: 0.125))
        case "CrashAudio5":
            rock?.components.set(AudioEventComponent(resourceName: "RockDrop", volumePercent: 0.0625))
        default:
            break
        }
    }
}

enum AudioCue: CaseIterable {
    case menuMusic
    case tutorialMusic
    case butteRiseMusic
    case gameplayMusic
    case outroMusic
    case fieryDescentSky
    case fieryDescentSFXSpatial
    case fieryDescentSFXAmbient
    case butteBottomAmbience

    var resourceName: String {
        switch self {
        case .menuMusic:
            "MenuMusic"
        case .tutorialMusic:
            "TutorialMusic"
        case .butteRiseMusic:
            "ButteRiseAndFadeIn"
        case .gameplayMusic:
            "GameplayMusic"
        case .outroMusic:
            "OutroMusic"
        case .fieryDescentSky:
            "FieryDescentSky"
        case .fieryDescentSFXSpatial:
            "FieryDescentSFX_Spatial"
        case .fieryDescentSFXAmbient:
            "FieryDescentSFX_Ambient"
        case .butteBottomAmbience:
            "ButteBottomAmbience"
        }
    }
}

extension Duration {
    var seconds: TimeInterval {
        Double(components.seconds) + Double(components.attoseconds) / 1e+18
    }
}
