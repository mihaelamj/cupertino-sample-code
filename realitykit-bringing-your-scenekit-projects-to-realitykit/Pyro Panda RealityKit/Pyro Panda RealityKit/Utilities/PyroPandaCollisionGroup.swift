/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The collision groups and filters for entities in the Pyro Panda game.
*/

import RealityKit

struct PyroPandaCollisionGroup {
    static let player = CollisionGroup(rawValue: 1 << 0)
    static let environment = CollisionGroup(rawValue: 1 << 1)
    static let lava = CollisionGroup(rawValue: 1 << 2)
    static let collectable = CollisionGroup(rawValue: 1 << 3)
    static let enemy = CollisionGroup(rawValue: 1 << 4)
    static let enemyWeapon = CollisionGroup(rawValue: 1 << 5)
    static let camera = CollisionGroup(rawValue: 1 << 6)
    static let cameraAdjusters = CollisionGroup(rawValue: 1 << 7)
    static let areaTrigger = CollisionGroup(rawValue: 1 << 8)
    static let door = CollisionGroup(rawValue: 1 << 9)
}

struct PyroPandaCollisionFilters {
    fileprivate static let movingCharacters: CollisionGroup = [PyroPandaCollisionGroup.player, PyroPandaCollisionGroup.enemy]

    static let enemyFilter = CollisionFilter(group: PyroPandaCollisionGroup.enemy, mask: PyroPandaCollisionGroup.player)
    static let enemyDeadFilter = CollisionFilter(group: PyroPandaCollisionGroup.enemy, mask: [
        PyroPandaCollisionGroup.environment, PyroPandaCollisionGroup.lava
    ])
    static let terrainFilter = CollisionFilter(group: PyroPandaCollisionGroup.environment, mask: movingCharacters)
    static let lavaFilter = CollisionFilter(group: PyroPandaCollisionGroup.lava, mask: movingCharacters)
    static let doorFilter = CollisionFilter(group: PyroPandaCollisionGroup.door, mask: movingCharacters)
    static let doorUnlockFilter = CollisionFilter(group: PyroPandaCollisionGroup.areaTrigger, mask: PyroPandaCollisionGroup.player)
    static let farBelowFilter = CollisionFilter(group: PyroPandaCollisionGroup.areaTrigger, mask: PyroPandaCollisionGroup.player)
    static let collectableFilter = CollisionFilter(group: PyroPandaCollisionGroup.collectable, mask: PyroPandaCollisionGroup.player)
}
