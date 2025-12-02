/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system controlling speech bubbles for the character's dialogue.
*/

import Combine
import RealityKit
import RealityKitContent
import Spatial

final class SpeechBubbleSystem: System {
    let query = EntityQuery(where: .has(SpeechBubbleComponent.self))
    
    var subscriptions: [AnyCancellable] = .init()
    required init(scene: RealityKit.Scene) {
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: CollisionEvents.Began.self, componentType: SpeechBubbleTriggerComponent.self) {
            self.onCollisionBegan(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidChangeGamePlayState(event: ComponentEvents.DidChange) {
        guard let gamePlayState = event.entity.components[GamePlayStateComponent.self] else {
            return
        }

        // Close any open speech bubbles when the intro animation begins.
        if gamePlayState == .introAnimation, let speechBubbleEntity = event.entity.first(withComponent: SpeechBubbleComponent.self)?.entity {
            speechBubbleEntity.components[SpeechBubbleComponent.self]?.scale = 0
            speechBubbleEntity.components[SpeechBubbleComponent.self]?.timer = 0
            speechBubbleEntity.components[SpeechBubbleComponent.self]?.isEnabled = false
        }

        // Reset the speech-bubble triggers when the game starts.
        if gamePlayState == .starting,
           let speechBubbleTriggers = event.entity.scene?.performQuery(EntityQuery(where: .has(SpeechBubbleTriggerComponent.self))) {
            for speechBubbleTrigger in speechBubbleTriggers {
                speechBubbleTrigger.components[SpeechBubbleTriggerComponent.self]?.hasBeenTriggered = false
                speechBubbleTrigger.findEntity(named: "Sphere")?.isEnabled = true
            }
        }
    }
    
    @MainActor
    func onCollisionBegan(event: CollisionEvents.Began) {
        guard let characterProgress = event.entityA.components[CharacterProgressComponent.self],
              let speechBubbleTriggerComponent = event.entityB.components[SpeechBubbleTriggerComponent.self],
              event.entityA.firstParent(withComponent: GamePlayStateComponent.self)?.component.isPlayingGame == true else {
            return
        }

        if !speechBubbleTriggerComponent.once || !speechBubbleTriggerComponent.hasBeenTriggered {
            // Activate the speech bubble.
            event.entityA.activateSpeechBubble(text: speechBubbleTriggerComponent.characterText,
                                               duration: speechBubbleTriggerComponent.timer,
                                               isDown: true)
            event.entityB.findEntity(named: "Sphere")?.isEnabled = false

            if event.entityA.firstParent(withComponent: GameInfoComponent.self)?.component.isTutorial == true {
                event.entityB.components.set(
                    AudioEventComponent(
                        resourceName: "Checkpoint\(characterProgress.triggeredSpeechBubbleIds.count + 1)"
                    )
                )
            }
        }
        
        event.entityB.components[SpeechBubbleTriggerComponent.self]?.hasBeenTriggered = true
        
        // Track progress toward speech-bubble tutorial completion.
        if characterProgress.targetNumSpeechBubbles > 0,
           speechBubbleTriggerComponent.isTutorialGoal,
           !characterProgress.triggeredSpeechBubbleIds.contains(event.entityB.id) {
            event.entityA.components[CharacterProgressComponent.self]?.triggeredSpeechBubbleIds.insert(event.entityB.id)
            let totalSpeechBubbles = event.entityA.components[CharacterProgressComponent.self]?.triggeredSpeechBubbleIds.count ?? 0
            if totalSpeechBubbles == characterProgress.targetNumSpeechBubblesRoll {
                event.entityA.scene?.postRealityKitNotification(notification: "TutorialComplete_1")
            } else if totalSpeechBubbles == characterProgress.targetNumSpeechBubblesJump {
                event.entityA.scene?.postRealityKitNotification(notification: "TutorialComplete_2")
            }
        }
    }

    func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        for speechBubble in context.entities(matching: query, updatingSystemWhen: .rendering) {
            guard var speechBubbleComponent = speechBubble.components[SpeechBubbleComponent.self] else {
                return
            }
            // Decrease the speech-bubble timer.
            speechBubbleComponent.timer -= deltaTime
            
            // Disable the speech bubble if the timer is at or below zero.
            if speechBubbleComponent.timer <= 0 && speechBubbleComponent.isEnabled {
                speechBubbleComponent.isEnabled = false
            }
            
            // Get the speech bubble's target position.
            let offset = speechBubbleComponent.offset * (speechBubbleComponent.isDown ? 1 : -1)
            var targetPosition = speechBubbleComponent.targetEntity.position(relativeTo: nil) + offset
            // Move the speech bubble to its target position, preventing it from going through the floor.
            targetPosition.y = max(targetPosition.y, -GameSettings.volumeSize.height / 2 + 0.05)
            speechBubble.setPosition(targetPosition, relativeTo: nil)
            
            // Update the speech-bubble component.
            speechBubble.components.set(speechBubbleComponent)
        }
    }
}
