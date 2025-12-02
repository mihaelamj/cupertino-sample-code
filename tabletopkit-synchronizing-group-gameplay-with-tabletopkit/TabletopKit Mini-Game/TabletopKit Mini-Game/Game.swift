/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A container to organize classes for the game.
*/
import TabletopKit
import RealityKit
import SwiftUI

@Observable
final class Game {
    let tabletopGame: TabletopGame
    let renderer: GameRenderer
    let observer: GameObserver
    let setup: GameSetup
    
    var gameStarted: Bool = false
    var isHost: Bool = false
    
    // Store the final pose of a player when a jump initiates from a pull-and-release motion.
    var programmaticPlayerInteractions: [TabletopInteraction.Identifier: Pose3D] = [:]
    
    enum LilyPadSinkState {
        case idle
        case started
        case sank
    }

    var lilyPadSinkStates: [EquipmentIdentifier: LilyPadSinkState] = [:]
    var lilyPadSinkTimers: [EquipmentIdentifier: Double] = [:]
    
    struct PlayerStat {
        var health: Int = 5 // 0 to 5
        var coinsCount: Int = 0
    }
    
    var playerStats: [PlayerStat] = []

    @MainActor
    init() {
        renderer = GameRenderer()
        setup = GameSetup()
        
        tabletopGame = TabletopGame(tableSetup: setup.setup)
        
        observer = GameObserver()
        tabletopGame.addObserver(observer)
        
        tabletopGame.addRenderDelegate(renderer)
        renderer.game = self
        observer.game = self

        tabletopGame.claimAnySeat()
        
        resetGame()
    }
    
    @MainActor func startGame() {
        gameStarted = true
        for index in 0..<logCount {
            _ = tabletopGame.startInteraction(onEquipmentID: .logID(for: index))
        }
        
        for index in PlayerSeat.seatPoses.indices {
            tabletopGame.addAction(ActivatePlayer(playerId: .playerID(for: index), seat: index))
        }
    }
    
    @MainActor func resetGame() {
        gameStarted = false
        tabletopGame.cancelAllInteractions()
        programmaticPlayerInteractions = [:]
        playerStats = []
        for index in PlayerSeat.seatPoses.indices {
            tabletopGame.addAction(ResetPlayer(playerId: .playerID(for: index), seat: index))
            playerStats.append(PlayerStat())
        }
        
        for index in 0..<coinCount {
            tabletopGame.addAction(ResetCoin(coinId: .coinID(for: index)))
        }
        
        for index in 0..<lilyPadCount {
            tabletopGame.addAction(ResetLilyPad(lilyPadId: .lilyPadID(for: index)))
            lilyPadSinkStates[.lilyPadID(for: index)] = .idle
            lilyPadSinkTimers[.lilyPadID(for: index)] = 0
        }
    }
    
    deinit {
        tabletopGame.removeObserver(observer)
        tabletopGame.removeRenderDelegate(renderer)
    }
}
