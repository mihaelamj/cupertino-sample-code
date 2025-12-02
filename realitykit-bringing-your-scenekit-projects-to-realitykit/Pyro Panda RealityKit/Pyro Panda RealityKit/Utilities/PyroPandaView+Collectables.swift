/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The parts of `PyroPandaView` that set up the collectable items.
*/

import RealityKit
import SwiftUI
import CharacterMovement
import WorldCamera
import PyroPanda
import ControllerInput
import HapticUtility

extension PyroPandaView {
    func setupCollectables(coin: Entity, key: Entity, content: some RealityViewContentProtocol) {
        coin.components.set([
            CollectableComponent(type: .coin)
        ])
        coin.components[CollisionComponent.self]?.mode = .trigger
        coin.components[CollisionComponent.self]?.filter = PyroPandaCollisionFilters.collectableFilter
        _ = content.subscribe(to: CollisionEvents.Began.self, on: coin, collectableCollision(event:))

        key.components.set([
            CollectableComponent(type: .key)

        ])
        key.components[CollisionComponent.self]?.mode = .trigger
        key.components[CollisionComponent.self]?.filter = PyroPandaCollisionFilters.collectableFilter
        _ = content.subscribe(to: CollisionEvents.Began.self, on: key, keyCollision(event:))
    }

    fileprivate func runKeyApparitionAnimation(key: Entity, camera: Entity) throws {
        var targetOffset: SIMD3<Float>? = .zero
        #if os(visionOS)
        targetOffset = [0, -0.75, 0]
        #endif
        let orientAction = CameraOrientAction(
            transitionIn: 0.5, transitionOut: 0.5,
            azimuth: .pi / 2, elevation: -.pi / 24,
            radius: 0.75, targetOffset: targetOffset, target: key.id
        )

        let orientAnim = try AnimationResource.makeActionAnimation(
            for: orientAction, duration: 4.5)
        CameraOrientActionHandler.register({ _ in CameraOrientActionHandler() })
        camera.playAnimation(orientAnim)

        // Pause the hero.
        if let hero = hero,
           var movementComponent = hero.components[CharacterMovementComponent.self] {
            movementComponent.paused = true
            hero.components.set(movementComponent)
        }

        CameraOrientAction.subscribe(to: .ended) { _ in
            if let hero = hero,
               var movementComponent = hero.components[CharacterMovementComponent.self] {
                movementComponent.paused = false
                hero.components.set(movementComponent)
            }
        }

        let fadeInAction = FromToByAction(to: Float(1.0))
        let fadeInAnim = try AnimationResource.makeActionAnimation(
            for: fadeInAction, duration: 1, bindTarget: .opacity, delay: 1)
        key.playAnimation(fadeInAnim)

        _ = try? self.appModel.gameAudioRoot?.playAudioWithAnimation(
            named: "collectBig", delay: 1)

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            guard let entity = try? await Entity(named: "Particles/key_apparition", in: pyroPandaBundle)
            else { return }
            key.addChild(entity)
        }
    }

    func collectableCollision(event: CollisionEvents.Began) {
        var coin = event.entityA
        var hero = event.entityB
        if hero.components.has(CollectableComponent.self) {
            swap(&coin, &hero)
        }

        guard let collectableComponent = coin.components[CollectableComponent.self]
        else { return }
        hero.components[HeroComponent.self]?.collectedItems.append(collectableComponent)
        _ = try? self.appModel.gameAudioRoot?.playAudioWithAnimation(named: "collect")

        HapticUtility.playHapticsFile(named: "Sparkle")
        
        Task {
            guard let entity = try? await Entity(named: "Particles/key_apparition", in: pyroPandaBundle)
            else { return }
            entity.transform = coin.transform
            appModel.gameRoot?.addChild(entity)
            
            coin.removeFromParent()
            appModel.collectedCoin = true
        }
        
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.0))
            coin.removeFromParent()
            guard let key = appModel.gameRoot?.findEntity(named: "key"),
                  let camera = appModel.gameRoot?.findEntity(named: "camera")
            else { return }

            try? runKeyApparitionAnimation(key: key, camera: camera)
        }
    }

    func keyCollision(event: CollisionEvents.Began) {
        var key = event.entityA
        var hero = event.entityB
        if hero.components.has(CollectableComponent.self) {
            swap(&key, &hero)
        }

        _ = try? self.appModel.gameAudioRoot?.playAudioWithAnimation(named: "collect")

        HapticUtility.playHapticsFile(named: "Sparkle")

        guard let collectableComponent = key.components[CollectableComponent.self] else { return }
        hero.components[HeroComponent.self]?.collectedItems.append(collectableComponent)
        key.components.remove(CollisionComponent.self)
        Task {
            guard let entity = try? await Entity(named: "Particles/key_apparition", in: pyroPandaBundle)
            else { return }
            key.addChild(entity)
            guard let collectBig = try? await Entity(named: "Particles/collect_big", in: pyroPandaBundle)
            else { return }
            key.addChild(collectBig)
        }
        key.recursiveCall { $0.components.remove(ModelComponent.self) }
        appModel.collectedKey = true
    }
}
