/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component tracking the character's progress through the game, and additional state data other systems rely on.
*/

import RealityKit

public struct CollectedRockFriend {
    var id: UInt64 = 0
    var nextCrumbIndex: Int = -1
    var jumpPos: SIMD3<Float> = [0, 0, 0]
    var jumpVel: SIMD3<Float> = [0, 0, 0]
    var jumpT: Float = -1
    var totalJumpTime: Float = 0
    var isLongJumping = false
    var jumpNextFrame = false
    var name: String = ""
}

struct Breadcrumb {
    var position: SIMD3<Float> = .zero
    var reservedByRockIndex = -1
}

struct CharacterProgressComponent: Component {
    var runDurationTimer: Float = 0
    var collectedRockFriends: [CollectedRockFriend] = []
    var triggeredSpeechBubbleIds = Set<UInt64>()
    var targetNumSpeechBubbles = -1
    var targetNumSpeechBubblesRoll = 3
    var targetNumSpeechBubblesJump = 6
    var isDifficultyHard = false
    static let totalCrumbs = 50
    var breadcrumbs: [Breadcrumb] = []
    var firstCrumb: Int = 0
}
