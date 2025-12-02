/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The component and action for a hero in a game.
*/

import Foundation
import RealityKit
import CharacterMovement
import Combine
import CoreHaptics

/// A component that tracks information about a hero entity.
struct HeroComponent: Component {
    var isAttacking: Bool = false
    var collectedItems: [CollectableComponent] = []
    var lavaHapticsPlayers: [CHHapticPatternPlayer] = []
}

struct HeroAttackAction: EntityAction {
    var animatedValueType: (any AnimatableData.Type)? { nil }

    init() {}
    static func animation(duration: TimeInterval) throws -> AnimationResource {
        try AnimationResource.makeActionAnimation(for: self.init(), duration: duration)
    }
}

@MainActor
struct HeroAttackActionHandler: @preconcurrency ActionHandlerProtocol {
    typealias ActionType = HeroAttackAction
    /// The function that the action calls at the beginning.
    mutating func actionStarted(event: EventType) {
        guard let targetEntity = event.playbackController.entity else {
            return
        }
        _ = try? CharacterStateComponent.updateState(
            for: targetEntity,
            to: .spin,
            movementSpeed: 1,
            childProxy: "Max"
        )
        targetEntity.components[HeroComponent.self]?.isAttacking = true
    }
    /// The function that the action calls at the end.
    func actionEnded(event: EventType) {
        event.playbackController.entity?
            .components[HeroComponent.self]?.isAttacking = false
    }
}
