/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A session controller extension that synchronizes the app's state with the SharePlay group session.
*/

import GroupActivities

extension SessionController {
    func shareLocalPlayerState(_ newValue: PlayerModel) {
        Task {
            do {
                // Send local player state with the group session messenger.
                try await messenger.send(newValue)
            } catch {
                print("The app can't send the player state message due to: \(error)")
            }
        }
    }
    
    func shareLocalGameState(_ newValue: GameModel) {
        gameSyncStore.editCount += 1
        gameSyncStore.lastModifiedBy = session.localParticipant
    
        let message = GameMessage(
            game: newValue,
            editCount: gameSyncStore.editCount
        )
        Task {
            do {
                // Send local game state with the group session messenger.
                try await messenger.send(message)
            } catch {
                print("The app can't send the game state message due to: \(error)")
            }
        }
    }
    
    func observeRemoteParticipantUpdates() {
        observeActiveRemoteParticipants()
        observeRemoteGameModelUpdates()
        observeRemotePlayerModelUpdates()
    }
    
    private func observeRemoteGameModelUpdates() {
        Task {
            // Listen for game state messages from other players with the group session messenger.
            // Update local game state with the returned message and context.
            for await (message, context) in messenger.messages(of: GameMessage.self) {
                let senderID = context.source.id
                
                let editCount = gameSyncStore.editCount
                let gameLastModifiedBy = gameSyncStore.lastModifiedBy ?? session.localParticipant
                let shouldAcceptMessage = if message.editCount > editCount {
                    true
                } else if message.editCount == editCount && senderID > gameLastModifiedBy.id {
                    true
                } else {
                    false
                }
                
                guard shouldAcceptMessage else {
                    continue
                }
                
                if message.game != gameSyncStore.game {
                    gameSyncStore.game = message.game
                }
                gameSyncStore.editCount = message.editCount
                gameSyncStore.lastModifiedBy = context.source
            }
        }
    }
    
    private func observeRemotePlayerModelUpdates() {
        Task {
            for await (player, context) in messenger.messages(of: PlayerModel.self) {
                players[context.source] = player
            }
        }
    }
    
    private func observeActiveRemoteParticipants() {
        // Create a list of remote participants by removing the local participant from the group
        // session's list of active participants.
        let activeRemoteParticipants = session.$activeParticipants.map {
            $0.subtracting([self.session.localParticipant])
        }
        .withPrevious()
        .values
        
        Task {
            // Listen for game state messages from other players with the group session messenger.
            // Update local game state with the returned message and context.
            for await (oldActiveParticipants, currentActiveParticipants) in activeRemoteParticipants {
                let oldActiveParticipants = oldActiveParticipants ?? []
                
                let newParticipants = currentActiveParticipants.subtracting(oldActiveParticipants)
                let removedParticipants = oldActiveParticipants.subtracting(currentActiveParticipants)
                
                if !newParticipants.isEmpty {
                    // Send new participants the current state of the game.
                    do {
                        let gameMessage = GameMessage(
                            game: game,
                            editCount: gameSyncStore.editCount
                        )
                        try await messenger.send(gameMessage, to: .only(newParticipants))
                    } catch {
                        print("Failed to send game catchup message, \(error)")
                    }
                    
                    // Send new participants the player model of the local participant.
                    do {
                        try await messenger.send(localPlayer, to: .only(newParticipants))
                    } catch {
                        print("Failed to send player catchup message, \(error)")
                    }
                }

                // Remove any participants that have left from the active players dictionary.
                for participant in removedParticipants {
                    players[participant] = nil
                }
            }
        }
    }
    
    struct GameSyncStore {
        var editCount: Int = 0
        var lastModifiedBy: Participant?
        var game = GameModel()
    }
}

struct GameMessage: Codable, Sendable {
    let game: GameModel
    let editCount: Int
}
