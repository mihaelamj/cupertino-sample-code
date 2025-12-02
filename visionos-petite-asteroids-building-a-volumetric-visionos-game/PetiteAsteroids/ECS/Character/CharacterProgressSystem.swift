/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that updates the character's progress.
*/

import Combine
import RealityKit
import RealityKitContent

final class CharacterProgressSystem: System {
    
    var subscriptions: [AnyCancellable] = .init()
    
    required init(scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidChange.self, componentType: GamePlayStateComponent.self) {
            self.onDidChangeGamePlayState(event: $0)
        }.store(in: &subscriptions)
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: GamePlayStateComponent.self) {
            self.onDidAddGamePlayState(event: $0)
        }.store(in: &subscriptions)
    }
    
    @MainActor
    func onDidAddGamePlayState(event: ComponentEvents.DidAdd) {
        onGameStateChanged(entity: event.entity)
    }
    
    @MainActor
    func onDidChangeGamePlayState(event: ComponentEvents.DidChange) {
        onGameStateChanged(entity: event.entity)
    }
    
    @MainActor
    func onGameStateChanged(entity: Entity) {
        guard let gameState = entity.components[GamePlayStateComponent.self],
              let characterEntity = entity.scene?.first(withComponent: CharacterProgressComponent.self)?.entity else { return }
        
        if gameState == .starting {
            characterEntity.components[CharacterProgressComponent.self]?.collectedRockFriends.removeAll()
            characterEntity.components[CharacterProgressComponent.self]?.triggeredSpeechBubbleIds.removeAll()
            characterEntity.components[CharacterProgressComponent.self]?.runDurationTimer = 0
            
            // Reset the speech-bubble win condition.
            let speechBubbles = characterEntity.scene?.performQuery(.init(where: .has(SpeechBubbleTriggerComponent.self)))
            var numSpeechBubblesForGoal = 0
            for speechBubbleEntity in speechBubbles! {
                guard let speechBubble = speechBubbleEntity.components[SpeechBubbleTriggerComponent.self], speechBubble.isTutorialGoal else {
                    continue
                }
                numSpeechBubblesForGoal += 1
            }
            characterEntity.components[CharacterProgressComponent.self]?.targetNumSpeechBubbles = numSpeechBubblesForGoal
        }
    }
}
