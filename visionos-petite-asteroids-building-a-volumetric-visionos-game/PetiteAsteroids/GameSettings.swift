/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of static settings for the game.
*/

import SwiftUI
import RealityKit
import RealityKitContent

struct GameSettings {
    // MARK: Character physics
    static let characterRadius: Float = 0.5
    static let characterWorldRadius: Float = characterRadius * scale
    static let characterRestitution: Float = 0.5
    static let characterFriction: Float = 0.4
    // MARK: Max move speeds
    static func maxMoveSpeedFor(state: CharacterMovementState) -> Float {
        switch state {
        case .onGround, .onSlope: 8
        case .onWall: 2
        case .inAir: 11.2
        }
    }
    static let onDownSlopeMaxMoveSpeed: Float = 8
    // MARK: Max fall speeds
    static func maxFallSpeedFor(state: CharacterMovementState) -> Float {
        switch state {
        case .onGround, .onSlope, .inAir: -30
        case .onWall: -2.5
        }
    }
    // MARK: Slow on bounce
    static let bounceImpulseThreshold: Float = 0.2
    static let bounceSlowFactor: Float = 2
    // MARK: Break after fall
    static let inAirFallDurationThreshold: Float = 0.4
    static let breakImpulseThreshold: Float = 0.4
    static let canRespawnDurationThreshold: Float = 3
    static let breakYDisplacementMaximum: Float = -1
    // MARK: Move accelerations
    static func accelerationFor(state: CharacterMovementState) -> Float {
        switch state {
        case .onGround, .onSlope, .inAir: 80
        case .onWall: 15
        }
    }
    static let stoppingAcceleration: Float = 80
    static let slowingAccelerationFactor: Float = 1.4
    static let reverseDirectionAccelerationFactor: Float = 1.5
    // MARK: Jump parameters
    static let jumpHeight: Float = 4
    static let wallJumpHeight: Float = 3
    static let wallJumpDistance: Float = 3
    static let jumpCoyoteTime: Float = 0.2
    static let wallJumpCoyoteTime: Float = 0.2
    static let jumpBufferTime: Float = 0.15
    static let jumpSurfaceSeparation: Float = 0.05
    // MARK: Surface detection
    static let isWallDotProductThreshold: Float = 0.166
    static let isSlopeDotProductThreshold: Float = 0.5
    static let slideCoyoteTime: Float = 0.15
    // MARK: Gravity
    static let baseGravity: Float = -68
    static let jumpGravity: Float = baseGravity * 1.2
    static let upSlopeGravity: Float = baseGravity / 5
    // MARK: Level boundary
    static let volumeSize: Size3DFloat = Size3DFloat(width: 1.5, height: 1.8, depth: 1.8)
    // The amount of time it takes for the level boundary to disappear after the player leaves the ground.
    static let levelBoundaryDisappearTime: Float = 0.4
    // MARK: Collision groups
    @MainActor static let collectedRockGroup: CollisionGroup = GameCollisionGroup.collectedRock.collisionGroup
    @MainActor static let promptTutorialGroup: CollisionGroup = GameCollisionGroup.promptTutorial.collisionGroup
    @MainActor static let levelBoundaryGroup: CollisionGroup = GameCollisionGroup.levelBoundary.collisionGroup
    @MainActor static let dropShadowCollisionGroup: CollisionGroup = GameCollisionGroup.shadowReceiver.collisionGroup
    @MainActor static let platformAnimationGroup: CollisionGroup = GameCollisionGroup.platformAnimation.collisionGroup
    // MARK: Animation
    static let animationFrameDuration: Float = Float(1) / Float(12)
    static let platformOffsetAnimationMaxImpulse: Float = 9
    static let platformOffsetAnimationSpringBackForce: Float = 0.27
    static let platformOffsetAnimationAmplitudeFactor: Float = 0.7
    static let shearAnimStretchFactor: Float = 0.02
    static let eyeAppearDelay: Float = 0.5
    static let eyeBlinkDuration: Float = 0.25
    static let playOutroNotification = "PlayOutro"
    static let maxSquashScale: SIMD3<Float> = [1.4, 0.7, 1.4]
    static let maxSquashImpulse: Float = 10
    static let maxSquashDuration: Float = 0.27
    // MARK: Configuration
    static let maxPlayerRunsRecorded: Int = 8
    // MARK: Input
    static let dragRadius: Float = 0.1
    static let dragMinimumDistance: Float = 0.0001
    // MARK: Scale
    static let scale: Float = 0.03
    static let levelDepthOffset: Float = -0.15
    // MARK: Portals
    static let portalBendRadius: Float = 0.15
    static let portalBendSegmentCount: Int = 20
    static let portalCornerRadius: Float = 0.71
    static let portalCornerSegmentCount: Int = 32
    static let isFloorPortalBent: Bool = false
    // MARK: Game start animation
    static let portalFadeInDuration: TimeInterval = 2
    static let butteRiseAnimationInitialOffset = GameSettings.volumeSize.height * 1.25
    static let butteRiseSpeechBubbleAppearDelay: TimeInterval = 2
    static let butteRiseSpeechBubbleAppearDuration: Float = 3
    static let butteRiseAnimationDuration: TimeInterval = 5
    static let mainLevelIntroAnimationDuration: TimeInterval = 7
    // MARK: Fade
    static let fadeDuration: Float = 2.5
    static let gradientGamma: Float = 0.6
    static let gradientStartY: Float = -1.15
    static let gradientEndY: Float = volumeSize.height / 2
    static let fadeColorBottom: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    static let fadeColorTop: CGColor = CGColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1)
    static let fadeOutTimingFunction: EasingFunction = .easeOutQuad
    static let fadeInTimingFunction: EasingFunction = .easeInQuad
    // MARK: Audio
    // Larger values make bounces more audible.
    static let dropAudioImpulseMultiplier: Float = 0.1
    static let rollAudioMaxInterval: Float = 2
    static let rollAudioMinInterval: Float = 0.1
    static let playRollAudioSpeedThreshold: Float = 1
    // Blend between ambience sounds based on the character's Y-position relative to `PhysicsRoot`.
    static let ambienceBlendMinHeight: Float = 0
    static let ambienceBlendMaxHeight: Float = 55
    // MARK: Notifications
    static let respawnNotification = "Respawn"
    // MARK: Outro
    static let outroButtePushBackAmount: Float = 0.1
    static let outroButtePushBackDuration: Float = 2.5
    static let outroCameraRotation: Float = 1.7
    static let outroCameraVerticalOffset: Float = -0.5
    static let outroCameraRotationAnimationDuration: Float = 6
    static let outroCameraTiltAnimationDuration: Float = 10
    static let outroCameraOffsetAnimationDuration: Float = 3
    static let outroCameraAnimationSmoothing: Float = 0.1
    static let butteFadeOutAnimationDuration: Float = 4
    // MARK: Drop shadow
    static let characterShadowRadius: Float = 0.55
    static let rockFriendShadowRadius: Float = 0.45
}
