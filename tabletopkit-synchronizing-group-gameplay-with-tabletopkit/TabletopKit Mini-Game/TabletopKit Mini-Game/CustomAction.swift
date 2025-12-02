/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Declarations of custom actions that the game uses.
*/
import TabletopKit
import Spatial

struct ResetPlayer: CustomAction {
    var playerId: EquipmentIdentifier
    var seat: Int

    func apply(table: inout TableState) {
        table.equipment.state[of: Player.self, id: playerId]?.base.seatControl = .restricted([])
        table.equipment.state[of: Player.self, id: playerId]?.base.parentID = .bankID(for: seat)
        table.equipment.state[of: Player.self, id: playerId]?.base.pose = .identity
        table.equipment.state[of: Player.self, id: playerId]?.health = 5
        table.equipment.state[of: Player.self, id: playerId]?.coinsCount = 0
    }
}

struct FreezePlayer: CustomAction {
    var playerId: EquipmentIdentifier

    func apply(table: inout TableState) {
        table.equipment.state[of: Player.self, id: playerId]?.base.seatControl = .restricted([])
    }
}

struct ActivatePlayer: CustomAction {
    var playerId: EquipmentIdentifier
    var seat: Int

    func apply(table: inout TableState) {
        table.equipment.state[of: Player.self, id: playerId]?.base.seatControl = .restricted([TableSeatIdentifier(seat)])
    }
}

struct DecrementHealth: CustomAction {
    var playerId: EquipmentIdentifier

    func apply(table: inout TableState) {
        table.equipment.state[of: Player.self, id: playerId]?.health -= 1
    }
}

struct CollectCoin: CustomAction {
    var playerId: EquipmentIdentifier
    var coinId: EquipmentIdentifier

    func apply(table: inout TableState) {
        table.equipment.state[of: Player.self, id: playerId]?.coinsCount += 1
        table.equipment.state[of: Coin.self, id: coinId]?.collected = true
    }
}

struct ResetCoin: CustomAction {
    var coinId: EquipmentIdentifier

    func apply(table: inout TableState) {
        table.equipment.state[of: Coin.self, id: coinId]?.collected = false
    }
}

struct SinkLilyPad: CustomAction {
    var lilyPadId: EquipmentIdentifier

    func apply(table: inout TableState) {
        if let lilyPad = table.equipment.state[of: LilyPad.self, id: lilyPadId] {
            if lilyPad.sank { return }
            table.equipment.state[of: LilyPad.self, id: lilyPadId]?.sank = true
        }
    }
}

struct ResetLilyPad: CustomAction {
    var lilyPadId: EquipmentIdentifier

    func apply(table: inout TableState) {
        if let lilyPad = table.equipment.state[of: LilyPad.self, id: lilyPadId] {
            if !lilyPad.sank { return }
            table.equipment.state[of: LilyPad.self, id: lilyPadId]?.sank = false
        }
    }
}
