/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A system that controls the blend effect between the top and bottom ambient audio playback controllers as the character moves up the butte.
*/

import Foundation
import Combine
import RealityKit

final class ButteAmbienceBlendSystem: System {

    static let query = EntityQuery(where: .has(ButteAmbienceBlendComponent.self))

    var subscriptions: Set<AnyCancellable> = []

    required init(scene: Scene) {
        scene.subscribe(to: ComponentEvents.DidAdd.self, componentType: AudioResourcesComponent.self) {
            self.onDidAddAudioResourcesComponent(event: $0)
        }.store(in: &subscriptions)
    }

    func update(context: SceneUpdateContext) {
        guard let characterEntity = context.first(withComponent: CharacterMovementComponent.self)?.entity,
              let physicsRoot = PhysicsSimulationComponent.nearestSimulationEntity(for: characterEntity),
              let gameState = characterEntity.scene?.first(withComponent: GamePlayStateComponent.self)?.component,
              gameState != .introAnimation else {
            return
        }

        let position = characterEntity.position(relativeTo: physicsRoot)
        let altitudeRange = GameSettings.ambienceBlendMinHeight...GameSettings.ambienceBlendMaxHeight
        let blend = position.y
            .map(from: altitudeRange, to: 0...1)
            .clamped(in: 0...1)

        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            let currentBlend = entity.components[ButteAmbienceBlendComponent.self]!.blend
            let interpolatedBlend = interpolate(
                current: currentBlend,
                target: blend,
                deltaTime: context.deltaTime
            )
            entity.components[ButteAmbienceBlendComponent.self]?.blend = interpolatedBlend
        }
    }

    func interpolate(current: Float, target: Float, deltaTime: TimeInterval) -> Float {
        let delta = target - current
        let deltaTimeScaled = Float(deltaTime) / 5
        return current + delta * deltaTimeScaled
    }

    @MainActor
    private func onDidAddAudioResourcesComponent(event: ComponentEvents.DidAdd) {
        guard let audioResources = event.entity.components[AudioResourcesComponent.self],
              let topFile = audioResources.get("ButteTopAmbience"),
              let ambientAudioEntity = event.entity.scene?.findEntity(named: "AmbientAudioEntity") else {
            return
        }

        let topPlaybackController = ambientAudioEntity.playAudio(topFile)
        topPlaybackController.gain = -.infinity
        ambientAudioEntity.components[ButteAmbienceBlendComponent.self]?.top = topPlaybackController
    }
}

extension BinaryFloatingPoint {
    func map(from domain: ClosedRange<Self>, to codomain: ClosedRange<Self>) -> Self {
        let proportion = (self - domain.lowerBound) / (domain.upperBound - domain.lowerBound)
        let scale = codomain.upperBound - codomain.lowerBound
        let offset = codomain.lowerBound
        return proportion * scale + offset
    }
}

extension Comparable {
    func clamped(in range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
