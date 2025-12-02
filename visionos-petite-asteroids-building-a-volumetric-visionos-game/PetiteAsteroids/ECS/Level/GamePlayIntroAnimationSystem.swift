/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that controls the gameplay intro animation.
*/

import Combine
import SwiftUI
import RealityKit
import RealityKitContent

final class GamePlayIntroAnimationSystem: System {
    var subscriptions: [AnyCancellable] = []

    init (scene: RealityKit.Scene) {
        scene.subscribe(to: ComponentEvents.DidChange.self,
                        componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidChangeGamePlayState (event: ComponentEvents.DidChange) {
        guard let gamePlayState = event.entity.components[GamePlayStateComponent.self],
              let gameInfo = event.entity.components[GameInfoComponent.self] else { return }
        
        switch gamePlayState {
            case .introAnimation:
                if gameInfo.isTutorial {
                    playTutorialIntroAnimation(entity: event.entity)
                } else {
                    playMainIntroAnimation(entity: event.entity)
                }
            case .starting:
                // Position the level root so that the level's origin is at the bottom of the volume.
                event.entity.findEntity(named: "LevelRoot")?.position = [0, -GameSettings.volumeSize.height / 2, GameSettings.levelDepthOffset]
            default:
                break
        }
    }
    
    @MainActor
    func playTutorialIntroAnimation (entity: Entity) {
        guard let rotationalCamera = entity.first(withComponent: RotationalCameraFollowComponent.self)?.entity else {
            return
        }
        if var rotationalCameraFollow = rotationalCamera.components[RotationalCameraFollowComponent.self] {
            rotationalCameraFollow.mode = .fixed
            rotationalCameraFollow.angle = 0
            rotationalCameraFollow.targetAngle = 0
            rotationalCameraFollow.cameraTiltAmount = 0
            rotationalCameraFollow.cameraTiltTarget = 0
            rotationalCameraFollow.cameraVerticalOffset = rotationalCameraFollow.cameraVerticalOffsetBottom
            rotationalCamera.components.set(rotationalCameraFollow)
        }
    }
    
    @MainActor
    func playMainIntroAnimation (entity: Entity) {
        guard let introAnimationConfig = entity.components[IntroAnimationConfigComponent.self],
              let characterEntity = entity.first(withComponent: CharacterMovementComponent.self)?.entity,
              let spawnPointEntity = entity.first(withComponent: CharacterSpawnPointComponent.self)?.entity.parent,
              let physicsRoot = entity.first(withComponent: PhysicsSimulationComponent.self)?.entity,
              let levelRoot = entity.findEntity(named: "LevelRoot") else {
            return
        }
        // Post the intro animation notification.
        entity.scene?.postRealityKitNotification(notification: "IntroAnimation")

        // Fade the level to black.
        levelRoot.setFadeAmountForDescendants(fadeAmount: 1)

        // Animate the level rising from the ground.
        playLevelRiseAnimation(
            levelRoot: levelRoot,
            characterEntity: characterEntity,
            spawnPointEntity: spawnPointEntity,
            physicsRoot: physicsRoot,
            preserveCharacterWorldPosition: introAnimationConfig.willPreserveCharacterWorldPosition
        )
        
        // Activate a speech bubble as the level emerges from the ground, if the config requests it.
        if introAnimationConfig.willShowSpeechBubble {
            activateSpeechBubbleAfterDelay(characterEntity: characterEntity, delay: GameSettings.butteRiseSpeechBubbleAppearDelay)
        }
        
        // Fade the level back in.
        Task { @MainActor in
            // Wait for the level fade start time.
            let startFadeTime = GameSettings.butteRiseAnimationDuration - (introAnimationConfig.willPreserveCharacterWorldPosition ? 0 : 0.5)
            try await Task.sleep(for: .seconds(startFadeTime))

            // Start fading the level back in and enable shadows.
            let fadeDuration = GameSettings.mainLevelIntroAnimationDuration - startFadeTime
            levelRoot.playFadeAnimationOnDescendants(fadeType: .fadeIn, duration: Float(fadeDuration), timingFunction: .easeInOutQuad)
            entity.scene?.applyBakedShadowShaderParameters(parameters: BakedDirectionalLightShadowSystem.ShadowParameters(receivesShadows: true))
            // Wait for the level to fade all the way back in.
            try await Task.sleep(for: .seconds(fadeDuration))
            
            // Start the game if the config requests it.
            if introAnimationConfig.willStartGameWhenComplete {
                entity.components.set(GamePlayStateComponent.starting)
            }
        }
    }
    
    @MainActor
    private func playLevelRiseAnimation(levelRoot: Entity,
                                        characterEntity: Entity,
                                        spawnPointEntity: Entity,
                                        physicsRoot: Entity,
                                        preserveCharacterWorldPosition: Bool) {
        guard var rotationalCameraFollow = physicsRoot.components[RotationalCameraFollowComponent.self] else {
            return
        }
        
        // Make the character a sibling of the level so that it does not move with the level, if the config requests it.
        let worldPosition = characterEntity.position(relativeTo: nil)
        let worldOrientation = characterEntity.orientation(relativeTo: nil)
        if preserveCharacterWorldPosition {
            characterEntity.setParent(levelRoot.parent)
            characterEntity.setPosition(worldPosition, relativeTo: nil)
            characterEntity.setOrientation(worldOrientation, relativeTo: nil)
        // Otherwise, teleport the player to the spawn point.
        } else {
            characterEntity.setPosition(spawnPointEntity.position(relativeTo: physicsRoot), relativeTo: physicsRoot)
        }
        
        // Rotate the level to align the spawn point with its target position.
        rotationalCameraFollow.mode = .fixed
        var toSpawn = spawnPointEntity.position(relativeTo: physicsRoot)
        toSpawn.y = 0
        var toTarget = preserveCharacterWorldPosition ? characterEntity.position(relativeTo: physicsRoot) :
                                                        physicsRoot.convert(position: [0, 0, 1], from: nil)
        toTarget.y = 0
        let angleBetweenTargetAndSpawn = signedAngleBetween(from: toSpawn, to: toTarget, axis: [0, 1, 0])
        rotationalCameraFollow.angle += angleBetweenTargetAndSpawn
        rotationalCameraFollow.targetAngle = rotationalCameraFollow.angle
        rotationalCameraFollow.cameraTiltAmount = 0
        rotationalCameraFollow.cameraTiltTarget = 0
        rotationalCameraFollow.cameraVerticalOffset = rotationalCameraFollow.cameraVerticalOffsetBottom
        physicsRoot.components.set(rotationalCameraFollow)

        // Animate the level rising from the ground.
        let volumeHeight = GameSettings.volumeSize.height
        let startTransform = Transform(translation: [0.0,
                                                     -volumeHeight / 2 - GameSettings.butteRiseAnimationInitialOffset,
                                                     GameSettings.levelDepthOffset])
        let endTransform = Transform(translation: [0.0, -volumeHeight / 2, GameSettings.levelDepthOffset])
        let transformAction = FromToByAction<Transform>(from: startTransform, to: endTransform, mode: .parent, timing: .easeOut)
        if let transformAnimation = try? AnimationResource.makeActionAnimation(for: transformAction,
                                                                               duration: Double(GameSettings.butteRiseAnimationDuration),
                                                                               bindTarget: .transform) {
            levelRoot.playAnimation(transformAnimation)
        }
        
        // Set the character back to being a descendent of the physics root when the animation completes, if the config requests it,
        // preserving its position and orientation.
        if preserveCharacterWorldPosition {
            Task { @MainActor in
                try await Task.sleep(for: .seconds(GameSettings.butteRiseAnimationDuration))
                characterEntity.setParent(physicsRoot)
                characterEntity.setPosition(worldPosition, relativeTo: nil)
                characterEntity.setOrientation(worldOrientation, relativeTo: nil)
            }
        }
    }
    
    private func activateSpeechBubbleAfterDelay(characterEntity: Entity, delay: TimeInterval) {
        Task { @MainActor in
            try await Task.sleep(for: .seconds(delay))
            characterEntity.activateSpeechBubble(text: "Ohhhh, sooo talll!",
                                                 duration: GameSettings.butteRiseSpeechBubbleAppearDuration,
                                                 isDown: true)
        }
    }
}
