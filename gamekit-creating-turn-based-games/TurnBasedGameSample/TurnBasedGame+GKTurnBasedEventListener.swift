/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension for turn-based games that handles turn-based listener events.
*/

import Foundation
@preconcurrency import GameKit
import SwiftUI

extension TurnBasedGame: GKTurnBasedEventListener {
    
    /// Creates a match and presents a matchmaker view controller.
    func player(_ player: GKPlayer, didRequestMatchWithOtherPlayers playersToInvite: [GKPlayer]) {
        startMatch(playersToInvite)
    }
    
    /// Handles multiple turn-based events during a match.
    func player(_ player: GKPlayer, receivedTurnEventFor match: GKTurnBasedMatch, didBecomeActive: Bool) {
        // Handles these turn-based events when:
        // 1. The local player accepts an invitation from another participant.
        // 2. GameKit passes the turn to the local player.
        // 3. The local player opens an existing or completed match.
        // 4. Another player forfeits the match.
              
        switch match.status {
        case .open:
            Task {
                do {
                    // If the match is open, first check whether game play should continue.
                    
                    // Remove participants who quit or otherwise aren't in the match.
                    let nextParticipants = match.participants.filter {
                        $0.status != .done
                    }

                    // End the match if active participants drop below the minimum.
                    if nextParticipants.count < minPlayers {
                        // Set the match outcomes for the active participants.
                        for participant in nextParticipants {
                            participant.matchOutcome = .won
                        }
                        
                        // End the match in turn.
                        try await match.endMatchInTurn(withMatch: match.matchData!)
                        
                        // Notify the local player when the match ends.
                        youWon = true
                    }
                    else if (currentMatchID == nil) || (currentMatchID == match.matchID) {
                        // If the local player isn't playing another match or is playing this match,
                        // display and update the game view.
                        
                        // Display the game view for this match.
                        playingGame = true
        
                        // Update the interface depending on whether it's the local player's turn.
                        myTurn = GKLocalPlayer.local == match.currentParticipant?.player ? true : false
        
                        // Remove the local player from the participants to find the opponent.
                        let participants = match.participants.filter {
                            self.localParticipant?.player.displayName != $0.player?.displayName
                        }
                        
                        // If the player starts the match, the opponent hasn't accepted the invitation and has no player object.
                        let participant = participants.first
                        if (participant != nil) && (participant?.status != .matching) && (participant?.player != nil) {
                            if opponent == nil {
                                // Load the opponent's avatar and create the opponent object.
                                let image = try await participant?.player?.loadPhoto(for: GKPlayer.PhotoSize.small)
                                opponent = Participant(player: (participant?.player)!,
                                                       avatar: Image(uiImage: image!))
                            }
                            
                            // Restore the current game data from the match object.
                            decodeGameData(matchData: match.matchData!)
                        }
                        
                        // Display the match message.
                        matchMessage = match.message
        
                        // Retain the match ID so action methods can load the current match object later.
                        currentMatchID = match.matchID
                    }
                                                            
                } catch {
                    // Handle the error.
                    print("Error: \(error.localizedDescription).")
                }
            }
        
        case .ended:
            print("Match ended.")

        case .matching:
            print("Still finding players.")

        default:
            print("Status unknown.")
        }
    }
    
    /// Handles when a player forfeits a match when it's their turn using the view controller interface.
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        // Remove the current participant. If the count drops below the minimum, the next participant ends the match.
        let nextParticipants = match.participants.filter {
            $0 != match.currentParticipant
        }
        
        // Quit while it's the local player's turn.
        match.participantQuitInTurn(with: GKTurnBasedMatch.Outcome.quit, nextParticipants: nextParticipants,
                                    turnTimeout: GKTurnTimeoutDefault, match: match.matchData!)
    }
    
    /// Handles when a participant ends the match using the view controller interface.
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        // Notify the local participant when the match ends.
        youLost = true
//        GKNotificationBanner.show(withTitle: "Match Ended Title",
//                                  message: "This is a GKNotificationBanner message.", completionHandler: nil)
//
//        // Check whether the local player is playing the match that ends before returning to the content view.
//        if currentMatchID == match.matchID {
//            resetGame()
//        }
    }
    
    // MARK: GKTurnBasedEventListener Exchange Methods
    
    /// Handles when the local player receives an exchange request from another participant.
    func player(_ player: GKPlayer, receivedExchangeRequest exchange: GKTurnBasedExchange,
                for match: GKTurnBasedMatch) {
        if exchange.data != nil {
            if exchange.message != "This is my exchange item request." {
                // Unpack the exchange data and display the message in the chat view.
                let content = String(decoding: exchange.data!, as: UTF8.self)
                let message = Message(content: content, playerName: exchange.sender.player?.displayName ?? "unknown", isLocalPlayer: false)
                messages.append(message)
            }
            
            // Reply to the exchange request.
            switch exchange.status {
            case .active:
                Task {
                    do {
                        // Alternatively, you can parse the message to present the request before accepting.
                        try await exchange.reply(withLocalizableMessageKey: "I accept the exchange request.", arguments: [], data: Data())
                    } catch {
                        // Handle the error.
                        print("Error: \(error.localizedDescription).")
                    }
                }
            case .complete:
                print("Exchange complete.")
            case .resolved:
                print("Exchange resolved.")
            case .canceled:
                print("Exchange canceled.")
            default:
                print("Exchange default.")
            }
        }
    }
    
    /// Handles when the sender cancels an exchange request.
    func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
    }
    
    /// Handles when all players either respond or time out responding to this request.
    func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply],
                forCompletedExchange exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
        // GameKit sends this message to both the current participant and the sender of the exchange request.
        saveExchanges(for: match)
    }

    /// Exchanges the items and removes completed exchanges from the match object.
    func saveExchanges(for match: GKTurnBasedMatch) {
        // Check whether the local player is the current participant who can save exchanges.
        guard myTurn else { return }
        
        // Save all the completed exchanges.
        if let completedExchanges = match.completedExchanges {
            
            for exchange in completedExchanges where exchange.message == "This is my exchange item request."{
                // For all exchange item requests, transfer an item from the recipient to the sender.
                if exchange.sender.player == localParticipant?.player {
                    // Transfer an item from the opponent to the local player.
                    opponent?.items -= 1
                    localParticipant?.items += 1
                } else {
                    // Transfer an item from the local player to the opponent.
                    localParticipant?.items -= 1
                    opponent?.items += 1
                }
                // For text message exchange requests, do nothing.
            }
 
            // Resolve the game data to pass to all participants.
            let gameData = (encodeGameData() ?? match.matchData)!

            // Save and forward the game data with the latest items.
            Task {
                try await match.saveMergedMatch(gameData, withResolvedExchanges: completedExchanges)
            }
        }
    }
}
