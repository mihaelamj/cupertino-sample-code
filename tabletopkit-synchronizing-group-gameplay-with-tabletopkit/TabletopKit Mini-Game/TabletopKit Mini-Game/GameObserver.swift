/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Responds to asynchronous callbacks throughout the gameplay.
*/
import RealityKit
import TabletopKit

class GameObserver: TabletopGame.Observer {
    weak var game: Game?

    func playerChangedSeats(_ player: TabletopKit.Player, oldSeat: (any TableSeat)?, newSeat: (any TableSeat)?, snapshot: TableSnapshot) {
        guard let game else {
            return
        }
        
        if player.id == game.tabletopGame.localPlayer.id, newSeat == nil {
            game.tabletopGame.claimAnySeat()
        }
        
        guard let (_, state) = snapshot.seat(of: PlayerSeat.self, matching: TableSeatIdentifier(0)) else { return }
        game.isHost = state.playerID == game.tabletopGame.localPlayer.id
    }
    
    func actionWasConfirmed(_ action: some TabletopAction, oldSnapshot: TableSnapshot, newSnapshot: TableSnapshot) {
        guard let game else {
            return
        }
        
        if let resetPlayerAction = ResetPlayer(from: action) {
            let (equip, state) = newSnapshot.equipment(of: Player.self, matching: [resetPlayerAction.playerId]).first!
            game.playerStats[equip.seat].health = state.health
            game.playerStats[equip.seat].coinsCount = state.coinsCount
            
            return
        }
        
        if let decrementHealthAction = DecrementHealth(from: action) {
            let (equip, state) = newSnapshot.equipment(of: Player.self, matching: [decrementHealthAction.playerId]).first!
            game.playerStats[equip.seat].health = state.health
            
            if action.playerID == game.tabletopGame.localPlayer.id && state.health == 0 {
                game.tabletopGame.addAction(FreezePlayer(playerId: equip.id))
            }
            
            return
        }
        
        if let collectCoinAction = CollectCoin(from: action) {
            let (playerEquip, playerState) = newSnapshot.equipment(of: Player.self, matching: [collectCoinAction.playerId]).first!
            game.playerStats[playerEquip.seat].coinsCount = playerState.coinsCount
            Task { @MainActor in
                playerEquip.playCollectAudio()
            }
            
            let (coinEquip, _) = newSnapshot.equipment(of: Coin.self, matching: [collectCoinAction.coinId]).first!
            Task { @MainActor in
                coinEquip.collect()
            }
            
            return
        }
        
        if let resetCoinAction = ResetCoin(from: action) {
            let (coinEquip, _) = newSnapshot.equipment(of: Coin.self, matching: [resetCoinAction.coinId]).first!
            Task { @MainActor in
                coinEquip.reset()
            }
            
            return
        }
    }
}
