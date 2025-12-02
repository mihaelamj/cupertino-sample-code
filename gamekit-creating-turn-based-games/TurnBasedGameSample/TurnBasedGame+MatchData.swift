/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension for turn-based games that handles match data that the game sends between players.
*/

import Foundation
import GameKit
import SwiftUI

// MARK: Game Data Objects

// A message that one player sends to another.
struct Message: Identifiable {
    var id = UUID()
    var content: String
    var playerName: String
    var isLocalPlayer: Bool = false
}

// A participant object with their items.
struct Participant: Identifiable {
    var id = UUID()
    var player: GKPlayer
    var avatar = Image(systemName: "person")
    var items = 50
}

// Codable game data for sending to players.
struct GameData: Codable {
    var count: Int
    var items: [String: Int]
}

extension TurnBasedGame {
    
    // MARK: Codable Game Data
    
    /// Creates a data representation of the game count and items for each player.
    ///
    /// - Returns: A representation of game data that contains only the game scores.
    func encodeGameData() -> Data? {
        // Create a dictionary of items for each player.
        var items = [String: Int]()
        
        // Add the local player's items.
        if let localPlayerName = localParticipant?.player.displayName {
            items[localPlayerName] = localParticipant?.items
        }
        
        // Add the opponent's items.
        if let opponentPlayerName = opponent?.player.displayName {
            items[opponentPlayerName] = opponent?.items
        }
        
        let gameData = GameData(count: count, items: items)
        return encode(gameData: gameData)
    }
    
    /// Creates a data representation from the game data for sending to other players.
    ///
    /// - Returns: A representation of the game data.
    func encode(gameData: GameData) -> Data? {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            let data = try encoder.encode(gameData)
            return data
        } catch {
            print("Error: \(error.localizedDescription).")
            return nil
        }
    }
    
    /// Decodes a data representation of game data and updates the scores.
    ///
    /// - Parameter matchData: A data representation of the game data.
    func decodeGameData(matchData: Data) {
        let gameData = try? PropertyListDecoder().decode(GameData.self, from: matchData)
        guard let gameData = gameData else { return }

        // Set the match count.
        count = gameData.count

        // Set the local player's items.
        if let localPlayerName = localParticipant?.player.displayName {
            if let items = gameData.items[localPlayerName] {
                localParticipant?.items = items
            }
        }

        // Set the opponent's items.
        if let opponentPlayerName = opponent?.player.displayName {
            if let items = gameData.items[opponentPlayerName] {
                opponent?.items = items
            }
        }
//        do {
//            if let gameData = try? PropertyListDecoder().decode(GameData.self, from: matchData) {
//                // Set the match count.
//                self.count = gameData.count
//
//                // Set the local player's items.
//                if let localParticipant = self.localParticipant {
//                    if let items = gameData.items[localParticipant.player.displayName] {
//                        self.localParticipant?.items = items
//                    }
//                }
//
//                // Set the opponent's items.
//                if let opponent = self.opponent {
//                    if let items = gameData.items[opponent.player.displayName] {
//                        self.opponent?.items = items
//                    }
//                }
//            }
//        }
    }
}
