/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The additions of the collision components and events to the Pyro Panda game.
*/

import Foundation
import RealityKit
import SwiftUI
import CharacterMovement
import ControllerInput
import HapticUtility

extension PyroPandaView {
    func setupEnvironmentCollisions(on world: Entity, content: any RealityViewContentProtocol) async {
        if let boundary = world.findEntity(named: "terrain_boundary") {
            try? await boundary.generateStaticShapeResources(recursive: true, filter: PyroPandaCollisionFilters.terrainFilter)
        }

        if let doorCollision = world.findEntity(named: "door")?.findEntity(named: "default") {
            doorCollision.components[CollisionComponent.self]?.filter = PyroPandaCollisionFilters.doorFilter
        }
        if let lavaCollision = world.findEntity(named: "lava_collision") {
            if let collLava = lavaCollision.findEntity(named: "COLL_lava") {
                try? await collLava.generateStaticShapeResources(
                    recursive: false, filter: PyroPandaCollisionFilters.lavaFilter
                )
                collLava.components.remove(ModelComponent.self)
            }
            if let triggerLava = lavaCollision.findEntity(named: "collision_trigger"),
               let triggerVulcano = lavaCollision.findEntity(named: "collision_trigger_vulcano") {

                triggerLava.components[CollisionComponent.self]?.mode = .trigger
                triggerVulcano.components[CollisionComponent.self]?.mode = .trigger

                triggerLava.components[CollisionComponent.self]?.filter = PyroPandaCollisionFilters.lavaFilter
                triggerVulcano.components[CollisionComponent.self]?.filter = PyroPandaCollisionFilters.lavaFilter

                OnFireSystem.registerSystem()

                _ = content.subscribe(to: CollisionEvents.Began.self, on: triggerLava, collideWithLava(event:))
                _ = content.subscribe(to: CollisionEvents.Ended.self, on: triggerLava, endCollideWithLava(event:))

                _ = content.subscribe(to: CollisionEvents.Began.self, on: triggerVulcano, collideWithLava(event:))
                _ = content.subscribe(to: CollisionEvents.Ended.self, on: triggerVulcano, endCollideWithLava(event:))
            }
        }

        if let doorUnlocker = world.findEntity(named: "unlock_door_collider") {
            doorUnlocker.components[CollisionComponent.self]?.mode = .trigger
            doorUnlocker.components[CollisionComponent.self]?.filter = PyroPandaCollisionFilters.doorUnlockFilter
            doorUnlocker.components.set(CollectableComponent(type: .key))
            _ = content.subscribe(to: CollisionEvents.Began.self, on: doorUnlocker, unlockDoor(event:))
        }

        if let farBelowCollider = world.findEntity(named: "collider_below") {
            farBelowCollider.components[CollisionComponent.self]?.mode = .trigger
            farBelowCollider.components[CollisionComponent.self]?.filter = PyroPandaCollisionFilters.farBelowFilter
            _ = content.subscribe(to: CollisionEvents.Began.self, on: farBelowCollider, resetMaxPosition(event:))
        }
    }

    func collideWithLava(event: CollisionEvents.Began) {
        guard let hero, event.entityB.id == hero.id else {
            return
        }
        hero.components.set(OnFireComponent(targetEntity: "Max"))
    }
    func endCollideWithLava(event: CollisionEvents.Ended) {
        guard let hero, event.entityB.id == hero.id else { return }
        hero.components.remove(OnFireComponent.self)
    }
    func unlockDoor(event: CollisionEvents.Began) {
        var doorUnlock = event.entityA
        var hero = event.entityB
        if hero.name == "unlock_door_collider" {
            swap(&doorUnlock, &hero)
        }

        _ = try? self.appModel.gameAudioRoot?.playAudioWithAnimation(named: "unlockTheDoor")

        HapticUtility.playHapticsFile(named: "Boing")

        // Check whether the hero has a key first.
        guard let heroComponent = hero.components[HeroComponent.self],
              heroComponent.collectedItems.contains(where: { $0.type == .key })
        else { return }
        doorUnlock.components.remove(CollisionComponent.self)

        Task {
            await self.gameCompleteEvent(hero: hero)
        }
    }
}

extension Entity {
    func generateStaticShapeResources(
        recursive: Bool = true,
        filter: CollisionFilter
    ) async throws {
        var shapes: [ShapeResource] = []
        if let meshResource = self.components[ModelComponent.self]?.mesh {
            try await shapes.append(ShapeResource.generateStaticMesh(from: meshResource))
        }
        self.components.set([
            CollisionComponent(shapes: shapes, mode: .default, collisionOptions: .static, filter: filter),
            PhysicsBodyComponent(shapes: shapes, mass: 1, mode: .static)
        ])
        if recursive {
            for child in self.children {
                try await child.generateStaticShapeResources(recursive: true, filter: filter)
            }
        }
    }
}
