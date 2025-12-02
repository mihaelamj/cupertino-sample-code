/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component and the enumerations it relies on to create a compound-collision component for an entity and all of its descendants.
*/

import RealityKit

public enum GameCollisionGroup: String, Codable {
    case all
    case collectedRock
    case promptTutorial
    case volumeBoundary
    case levelBoundary
    case shadowReceiver
    case platformAnimation
    
    public var collisionGroup: CollisionGroup {
        switch self {
            case .all:
                .all
            case .collectedRock:
                CollisionGroup(rawValue: 1 << 2)
            case .promptTutorial:
                CollisionGroup(rawValue: 1 << 3)
            case .volumeBoundary:
                CollisionGroup(rawValue: 1 << 4)
            case .levelBoundary:
                CollisionGroup(rawValue: 1 << 5)
            case .shadowReceiver:
                CollisionGroup(rawValue: 1 << 6)
            case .platformAnimation:
                CollisionGroup(rawValue: 1 << 8)
        }
    }
}

public enum GameCollisionMask: String, Codable {
    case all
    case allSubtractingLevelBoundary
    case allSubtractingCollectedRock
    
    public var collisionGroup: CollisionGroup {
        switch self {
            case .all:
                .all
            case .allSubtractingLevelBoundary:
                .all.subtracting(GameCollisionGroup.levelBoundary.collisionGroup)
            case .allSubtractingCollectedRock:
                .all.subtracting(GameCollisionGroup.collectedRock.collisionGroup)
        }
    }
}

public struct CompoundCollisionMarkerComponent: Component, Codable {
    public var isStatic: Bool = true
    public var deleteModel: Bool = false
    public var group: GameCollisionGroup = .all
    public var mask: GameCollisionMask = .all
    public var restitution: Float = 0.5
    public var friction: Float = 0.5
    public init() {
    }
}
