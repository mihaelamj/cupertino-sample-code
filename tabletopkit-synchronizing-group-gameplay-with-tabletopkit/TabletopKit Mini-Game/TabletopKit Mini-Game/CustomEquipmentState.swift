/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Declarations of custom equipment states that the game uses.
*/
import TabletopKit

struct PlayerState: CustomEquipmentState, BitwiseCopyable {
    var base: BaseEquipmentState
    var health: Int = 5 // 0 to 5
    var coinsCount: Int = 0
}

struct CoinState: CustomEquipmentState, BitwiseCopyable {
    var base: BaseEquipmentState
    var collected: Bool = false
}

struct LilyPadState: CustomEquipmentState, BitwiseCopyable {
    var base: BaseEquipmentState
    var sank: Bool = false
}
