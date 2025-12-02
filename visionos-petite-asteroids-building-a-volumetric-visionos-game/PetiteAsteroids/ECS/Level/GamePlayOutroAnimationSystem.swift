/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that controls the gameplay outro animation.
*/

import Combine
import SwiftUI
import RealityKit
import RealityKitContent

final class GamePlayOutroAnimationSystem: System {
    
    var subscriptions: [AnyCancellable] = []
    
    required init (scene: RealityKit.Scene) {
        scene.subscribe(to: ComponentEvents.DidChange.self,
                        componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self,
                        componentType: NotificationComponent.self) {
            self.onDidAddNotificationComponent(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidChangeGamePlayState (event: ComponentEvents.DidChange) {
        // Guard for the outro animation gameplay state, and make sure this is the main level.
        guard event.entity.components[GamePlayStateComponent.self] == .outroAnimation,
              event.entity.components[GameInfoComponent.self]?.currentLevel == .main else { return }
        
        playOutroAnimation(entity: event.entity)
    }
        
    @MainActor
    func onDidAddNotificationComponent (event: ComponentEvents.DidAdd) {
        guard let notification = event.entity.components[NotificationComponent.self],
              let rootEntity = event.entity.firstParent(withComponent: GamePlayStateComponent.self)?.entity else { return }
        
        // Respond to notifications relevant to the gameplay outro.
        switch notification.name {
            case "FadeToBlack":
                rootEntity.playFadeAnimationOnDescendants(fadeType: .fadeOut,
                                                          duration: GameSettings.butteFadeOutAnimationDuration,
                                                          timingFunction: .easeOutQuad)
            case "EnterPostGame":
                rootEntity.components.set(GamePlayStateComponent.postGame)
            default:
                break
        }
    }
    
    @MainActor
    func playOutroAnimation (entity: Entity) {
        // Guard for the entities necessary for the outro animation.
        guard let characterEntity = entity.first(withComponent: CharacterMovementComponent.self)?.entity,
              let finalRestingPointEntity = entity.first(withComponent: FinalRestingPointMarkerComponent.self)?.entity,
              let physicsRoot = entity.first(withComponent: PhysicsSimulationComponent.self)?.entity,
              let levelRoot = entity.findEntity(named: "LevelRoot") else { return }
        
        // Play an animation that pushes the butte backward.
        let yPosition = -GameSettings.volumeSize.height / 2
        let startTransform = Transform(translation: [0.0, yPosition, GameSettings.levelDepthOffset])
        let endTransform = Transform(translation: [0.0, yPosition, GameSettings.levelDepthOffset - GameSettings.outroButtePushBackAmount])
        let transformAction = FromToByAction<Transform>(from: startTransform, to: endTransform, mode: .parent, timing: .easeInOut)
        if let transformAnimation = try? AnimationResource.makeActionAnimation(for: transformAction,
                                                                               duration: Double(GameSettings.outroButtePushBackDuration),
                                                                               bindTarget: .transform) {
            levelRoot.playAnimation(transformAnimation)
        }
        
        Task { @MainActor in
            // Play the camera animation.
            let cameraAnimationParameters = CameraAnimationParameters(
                toRotation: GameSettings.outroCameraRotation,
                rotationAnimationDuration: GameSettings.outroCameraRotationAnimationDuration,
                toTilt: 0,
                tiltAnimationDuration: GameSettings.outroCameraTiltAnimationDuration,
                toOffset: GameSettings.outroCameraVerticalOffset,
                offsetAnimationDuration: GameSettings.outroCameraOffsetAnimationDuration,
                smoothing: GameSettings.outroCameraAnimationSmoothing
            )
            physicsRoot.playCameraAnimation(parameters: cameraAnimationParameters)
            
            // Tell the character to move toward its final resting point.
            let targetMovePosition = finalRestingPointEntity.position(relativeTo: physicsRoot)
            characterEntity.components[CharacterMovementComponent.self]?.targetMovePosition = targetMovePosition
            characterEntity.components[CharacterMovementComponent.self]?.targetMoveInputStrength = 0
            
            // Wait until the character reaches the final resting point position.
            let deltaTime = Float(1.0 / 90.0)
            while characterEntity.components[CharacterMovementComponent.self]?.targetMovePosition != nil {
                // Increase input strength to its maximum value over the course of half a second for a smoother animation.
                characterEntity.components[CharacterMovementComponent.self]?.targetMoveInputStrength += deltaTime * 2
                // Wait for the next frame.
                try await Task.sleep(nanoseconds: UInt64(Float(NSEC_PER_SEC) * deltaTime))
            }
            
            entity.scene?.postRealityKitNotification(notification: GameSettings.playOutroNotification)
        }
    }
}
