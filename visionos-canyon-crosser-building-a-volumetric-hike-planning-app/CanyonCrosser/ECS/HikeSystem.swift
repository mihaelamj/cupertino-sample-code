/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system to update the hiker when any of the hike components update.
*/

import Foundation
import RealityKit

struct HikeSystem: System {
    static let hikerEntityQuery = EntityQuery(
        where: .has(HikerProgressComponent.self)
        && .has(HikeTimingComponent.self)
        && .has(HikerDragStateComponent.self)
        && .has(HikePlaybackStateComponent.self)
    )

    init(scene: RealityKit.Scene) { }

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.hikerEntityQuery, updatingSystemWhen: .rendering) {
            guard
                animateHiker(deltaTime: context.deltaTime, entity: entity) == false
            else {
                return
            }

            guard
                var progressComponent = entity.components[HikerProgressComponent.self],
                let timingComponent = entity.components[HikeTimingComponent.self],
                let dragStateComponent = entity.components[HikerDragStateComponent.self],
                var playbackStateComponent = entity.components[HikePlaybackStateComponent.self]
            else {
                continue
            }

            // When pausing playback, or when a drag is in progress, exit from this function.
            guard
                !playbackStateComponent.isPaused,
                dragStateComponent.dragState == .none
            else { return }

            guard progressComponent.hikeProgress < 1.0 else {
                playbackStateComponent.isPaused = true

                entity.components[HikePlaybackStateComponent.self] = playbackStateComponent

                return
            }

            // Adjust the speed of the hiker relative to actual time such that it's 450x quicker than real-time playback.
            let desiredPlaybackDurationInSeconds = timingComponent.hikeTime / 450.0
            let progressPerSecond = 1.0 / desiredPlaybackDurationInSeconds
            let deltaProgress: Double = progressPerSecond * context.deltaTime

            progressComponent.hikeProgress = min(1.0, progressComponent.hikeProgress + Float(deltaProgress))

            entity.components[HikerProgressComponent.self] = progressComponent
        }
    }

    @MainActor
    private func animateHiker(deltaTime: TimeInterval, entity: Entity) -> Bool {
        let animationTime: TimeInterval = 0.2

        guard let animation = entity.components[HikerProgressComponent.self]?.animation else { return false }

        guard
            animation.elapsedTime < animationTime
        else {
            entity.components[HikerProgressComponent.self]?.animation = nil
            entity.components[HikerProgressComponent.self]?.hikeProgress = animation.toValue
            return false
        }

        let totalElapsedTime: TimeInterval = animation.elapsedTime + deltaTime
        let animationProgress = totalElapsedTime / animationTime

        let newValue = (animation.fromValue + (animation.toValue - animation.fromValue) * Float(animationProgress))
            .clamped(to: min(animation.toValue, animation.fromValue)...max(animation.toValue, animation.fromValue))

        entity.components[HikerProgressComponent.self]?.hikeProgress = newValue

        let hikeAnimation = (toValue: animation.toValue, fromValue: animation.fromValue, elapsedTime: totalElapsedTime)
        entity.components[HikerProgressComponent.self]?.animation = hikeAnimation
        return true
    }
}

