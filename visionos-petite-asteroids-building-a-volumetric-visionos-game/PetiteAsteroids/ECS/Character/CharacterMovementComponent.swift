/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component containing state data for the character's movement.
*/

import RealityKit
import SwiftUI

struct CharacterMovementComponent: Component {
    // Create shader parameters for each material instance in the scene.
    let shearDirectionParameterHandle = ShaderGraphMaterial.parameterHandle(name: "direction")
    let shearIntensityParameterHandle = ShaderGraphMaterial.parameterHandle(name: "intensity")
    var animationEntity: Entity?
    var velocity: SIMD3<Float> = .zero
    /// The cached speed, calculated once per frame.
    var currentSpeed: Float = 0
    var angularVelocity: SIMD3<Float> = .zero
    var inputMoveDirection: SIMD3<Float> = .zero
    var dragDelta: SIMD3<Float> = .zero
    var hasMoveInput: Bool {
        return inputMoveDirection != .zero
    }
    var jumpBufferTimer: Float = 0
    var jumpGravityTimer: Float = 0
    let jumpSpeed: Float
    let jumpGravityDuration: Float
    let wallJumpVerticalSpeed: Float
    let wallJumpHorizontalSpeed: Float
    let wallJumpGravityDuration: Float
    var isSlidingTimer: Float = 0
    var canJumpTimer: Float = 0
    var canWallJumpTimer: Float = 0
    var state: CharacterMovementState = .inAir
    var lastSlopeNormal: SIMD3<Float> = .zero
    var lastWallNormal: SIMD3<Float> = .zero
    var fallingTimer: Float = 0
    var canRespawnTimer: Float = 0
    var collisionClassificationByEntity: [Entity: CollisionClassification] = [:]
    var positionDelta: SIMD3<Float> = .zero
    var previousPosition: SIMD3<Float> = .zero
    var targetMovePosition: SIMD3<Float>? = nil
    var targetJumpPosition: SIMD3<Float>? = nil
    var targetMoveInputStrength: Float = 1
    var didWallJump = false
    var currentPlatformIndex: Int? = nil
    var disableLevelBoundaryTimer: Float = 0
    var canCollideWithLevelBoundary: Bool = true
    
    @MainActor
    init() {
        canRespawnTimer = GameSettings.canRespawnDurationThreshold
        
        jumpSpeed = ProjectileMotionUtilities.calculateVelocityNeededToReachHeight(height: GameSettings.jumpHeight, gravity: GameSettings.jumpGravity)
        
        jumpGravityDuration = ProjectileMotionUtilities.calculateTimeToReachMaxHeight(velocity: jumpSpeed, gravity: GameSettings.jumpGravity)
        
        wallJumpVerticalSpeed = ProjectileMotionUtilities.calculateVelocityNeededToReachHeight(height: GameSettings.wallJumpHeight,
                                                                                               gravity: GameSettings.jumpGravity)
        
        wallJumpHorizontalSpeed = ProjectileMotionUtilities.calculateVelocityNeededToTravelDistanceBeforeReachingTargetVelocity(
            distance: GameSettings.wallJumpDistance,
            targetVelocity: GameSettings.maxMoveSpeedFor(state: .inAir),
            slowingAcceleration: GameSettings.accelerationFor(state: .inAir) * (GameSettings.slowingAccelerationFactor - 1)
        )
        
        wallJumpGravityDuration = ProjectileMotionUtilities.calculateTimeToReachMaxHeight(velocity: wallJumpVerticalSpeed,
                                                                                          gravity: GameSettings.jumpGravity)
    }
}

enum CollisionClassification: Equatable {
    case ground
    case slope(normal: SIMD3<Float>)
    case wall(normal: SIMD3<Float>)
    case ceiling

    var isGroundOrSlope: Bool {
      switch self {
          case .ground, .slope(_): return true
          default: return false
      }
   }
}

enum CharacterMovementState: Sendable, Equatable {
    case onGround
    case onSlope
    case onWall
    case inAir
    
    public var isOnGroundOrSlope: Bool {
        switch self {
            case .onGround, .onSlope: true
            default: false
        }
    }
}
