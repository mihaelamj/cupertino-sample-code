/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App model extensions for receiving, handling, and delegating notifications.
*/

import SwiftUI
import RealityKit
import RealityKitContent

extension AppModel {
    func onReceiveNotification(notification: NotificationCenter.Publisher.Output) {
        guard let notificationName = notification.userInfo?["RealityKit.NotificationTrigger.Identifier"] as? String else { return }
        
        // Send the notification to ECS.
        sendNotificationToECS(notificationName)
        
        // Handle the notification.
        handleTutorialIntroNotification(notificationName: notificationName)
        handleTutorialPromptNotification(notificationName: notificationName)
        handleTutorialOutroNotification(notificationName: notificationName)
        handleMainLevelOutroNotification(notificationName: notificationName)
    }
    
    private func handleTutorialIntroNotification(notificationName: String) {
        switch notificationName {
        case "PromptReadyToPlay":
            root.scene?.postRealityKitNotification(notification: "StartIntro")
        case "StartIntro":
            tutorialPromptAttachmentRoot.removeFromParent()
            currentIntroSpeechBubbleIndex = 0
        case "IntroParticleFadeIn":
            guard let particleEmitterBig = root.findEntity(named: "ParticleEmitterBig"),
                  let particleEmitterSmall = root.findEntity(named: "ParticleEmitterSmall"),
                  let particleEmitterCenter = root.findEntity(named: "ParticleEmitterCenter"),
                  let introSpotLight = root.findEntity(named: "IntroSpotLight") else { return }
            
            particleEmitterBig.components[IntroParticleAnimationComponent.self]?.fadeIn = true
            particleEmitterSmall.components[IntroParticleAnimationComponent.self]?.fadeIn = true
            particleEmitterCenter.components[IntroParticleAnimationComponent.self]?.fadeIn = true
            introSpotLight.components[IntroParticleAnimationComponent.self]?.fadeIn = true
        case "NextIntroSpeechBubble":
            guard let introCharacterModel = self.root.findEntity(named: "FallDirectionRot")?.children.first else { return }
            introCharacterModel.activateSpeechBubble(text: introSpeechBubbleText[currentIntroSpeechBubbleIndex],
                                                     duration: 2,
                                                     isDown: false,
                                                     scale: 1.5)
            currentIntroSpeechBubbleIndex += 1
        case "IntroSpeechBubbleClose" :
            speechBubble.components[SpeechBubbleComponent.self]?.timer = 0
        case "StartTutorial":
            root.components.set(GamePlayStateComponent.starting)
            default:
            break
        }
    }
    
    private func handleTutorialPromptNotification(notificationName: String) {
        switch notificationName {
        case "PromptTutorialControls":
            tutorialPromptAttachmentRoot.components.set(tutorialPromptRoll)
            tutorialPromptAttachmentRoot.setParent(root)
        case "PromptTutorialJump":
            tutorialPromptAttachmentRoot.components.set(tutorialPromptJump)
            tutorialPromptAttachmentRoot.setParent(root)
        case "TutorialComplete_2":
            tutorialPromptAttachmentRoot.components.set(tutorialPromptComplete)
            tutorialPromptAttachmentRoot.setParent(root)
        default:
            break
        }
    }
    
    private func handleTutorialOutroNotification(notificationName: String) {
        switch notificationName {
        case "TutorialOutro":
            tutorialPromptAttachmentRoot.removeFromParent()
            root.components.set(GamePlayStateComponent.outroAnimation)
        case "TransitionToMainLevel":
            Task { @MainActor in
                guard let mainLevel = root.components[GameAssetContainer.self]?.levels[.main],
                      let spawnPointEntity = mainLevel.findEntity(named: "CharacterSpawnPoint_Origin"),
                      let physicsRoot = mainLevel.findEntity(named: "PhysicsRoot") else {
                    return
                }
                // Tell the character to move outward from the center of the physics root until it's at the same distance as the spawn point.
                // This ensures the character can align with the spawn point as you transition to the main level.
                var toCharacter = character.position
                toCharacter.y = 0
                toCharacter = length_squared(toCharacter) == 0 ? [0, 0, 1] : normalize(toCharacter)
                var spawnPosition = spawnPointEntity.position(relativeTo: physicsRoot)
                spawnPosition.y = 0
                let spawnPointDistance = length(spawnPosition)
                character.components[CharacterMovementComponent.self]?.targetMovePosition = toCharacter * spawnPointDistance
                character.components[CharacterMovementComponent.self]?.targetMoveInputStrength = 0
                
                // Wait until the character reaches its target position.
                let deltaTime = 1.0 / 90.0
                while character.components[CharacterMovementComponent.self]?.targetMovePosition != nil {
                    // Increase input strength to its maximum value over the course of half a second for a smoother animation.
                    character.components[CharacterMovementComponent.self]?.targetMoveInputStrength += Float(deltaTime) * 2
                    // Wait for the next frame.
                    try? await Task.sleep(for: .seconds(deltaTime))
                }
                
                // Briefly pause before transitioning to the main level.
                try? await Task.sleep(for: .seconds(1))
                playLevel(gameLevel: .main, introAnimationConfig: IntroAnimationConfigComponent(willPreserveCharacterWorldPosition: true))
            }
        default:
            break
        }
    }
    
    private func handleMainLevelOutroNotification(notificationName: String) {
        switch notificationName {
        case "NextOutroSpeechBubble":
            character.activateSpeechBubble(text: outroSpeechBubbleText[currentOutroSpeechBubbleIndex], duration: 3, isDown: true)
            currentOutroSpeechBubbleIndex += 1
        case "EnterPostGame" :
            menuVisibility = .highScore
            currentOutroSpeechBubbleIndex = 0
        default:
            break
        }
    }
    
    func sendNotificationToECS(_ notificationName: String) {
        root.components.set(NotificationComponent(name: notificationName))
        root.components.remove(NotificationComponent.self)
    }
}
