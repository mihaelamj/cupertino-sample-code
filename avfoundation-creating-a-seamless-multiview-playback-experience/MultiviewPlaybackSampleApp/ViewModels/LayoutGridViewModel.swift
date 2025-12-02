/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model to display a players in an adjustable layout.
*/

import SwiftUI
import AVFoundation
import os

@Observable
class LayoutGridViewModel {
    var selectedItem: MenuItem // The menu item.
    var selectedItemAssets: [MenuAsset] // The menu item assets to choose from.
    
    var playersToShow: [PlayerState] = [] // Array of all the players to display.
    var numGridColumns = 0 // Number of columns in the grid.
    var numGridRows = 0 // Number of rows in the grid.
    
    var focusPlayerIndex = 0 // Index of the player in focus.
    var focusPlayerID = "" // ID of the player in focus.
    var fullscreenPlayer: PlayerState?  // Player that is in full screen.
    
    var coordinationMedium: AVPlaybackCoordinationMedium // Playback coordination medium to use.
    
    // MARK: - Life Cycle
    
    init(selectedItem: MenuItem) {
        self.selectedItem = selectedItem
        selectedItemAssets = selectedItem.assets
        coordinationMedium = AVPlaybackCoordinationMedium()
    }
    
    func invalidate() {
        for player in playersToShow {
            player.invalidate()
        }
    }
    
    // Reset all properties to their initial state.
    func resetValues() {
        invalidate()
        playersToShow = []
        numGridColumns = 0
        numGridRows = 0
        focusPlayerIndex = 0
        focusPlayerID = ""
    }
    
    // MARK: - Grid Updates
    
    // Create an array of players for a given menu item.
    func createAllPlayers() {
        Logger.general.log("[LayoutGridViewModel] Creating grid of \(self.selectedItem.assets.count) players for item \(self.selectedItem.id)")
        
        resetValues()
        
        for (index, asset) in selectedItem.assets.enumerated() {
            let playerState = PlayerState(assetURL: asset.url, assetID: asset.id, networkPriority: (asset.networkPriority ?? .defaultPriority))
            
            // Connect the player to the coordination medium.
            playerState.connectToAVFCoordinationMedium(coordinationMedium: coordinationMedium)
            
            // Default set the focus player as unmuted.
            let isFocusPlayer = (index == focusPlayerIndex)
            if isFocusPlayer {
                playerState.toggleFocus(isFocused: true)
                focusPlayerID = playerState.playerID
            } else {
                playerState.toggleFocus(isFocused: false)
            }
            
            playersToShow.append(playerState)
        }
        
        updateLayoutGridValues()
    }
    
    // MARK: - Layout Updates
    
    // Update the players in each of the primary and secondary grids.
    func updateLayoutGridValues() {
        Logger.general.log("[LayoutGridViewModel] Updating layout grid values for \(self.playersToShow.count) players")
        
        let playersInGridCount = playersToShow.count
        numGridColumns = Int(Double(playersInGridCount).squareRoot())
        numGridRows = (numGridColumns == 0) ? 0 : Int(ceil(Double(playersInGridCount) / Double(numGridColumns)))
    }
    
    // Add a player to the layout view.
    func addPlayerToLayout(asset: MenuAsset) {
        // Create the player and default add the player to the grid.
        let playerState = PlayerState(assetURL: asset.url, assetID: asset.id, networkPriority: asset.networkPriority ?? .defaultPriority)
        Logger.general.log("[LayoutGridViewModel] [\(playerState.playerID)] Adding player to layout")
        
        // Connect the player to coordination medium.
        playerState.connectToAVFCoordinationMedium(coordinationMedium: coordinationMedium)
        
        // Default: set the first player as focused.
        let isFocusPlayer = (playersToShow.count == focusPlayerIndex)
        if isFocusPlayer {
            playerState.toggleFocus(isFocused: true)
            focusPlayerID = playerState.playerID
        } else {
            playerState.toggleFocus(isFocused: false)
        }
        
        playersToShow.append(playerState)
        
        updateLayoutGridValues()
    }
    
    // Remove a player from the layout view.
    func removePlayerFromLayout(playerID: String) {
        Logger.general.log("[LayoutGridViewModel] [\(playerID)] Removing player from layout")
        
        if let index = playersToShow.firstIndex(where: { $0.playerID == playerID }) {
            playersToShow[index].invalidate()
            
            // Remove the player from the view model.
            playersToShow.remove(at: index)
            updateLayoutGridValues()
            
            // Reset the focus player and automatically assign it to the first player.
            if focusPlayerIndex == index && !playersToShow.isEmpty {
                setFocusOnPlayer(playerID: playersToShow[0].playerID)
            }
        }
    }
    
    // Set focus on the selected player.
    func setFocusOnPlayer(playerID: String) {
        Logger.general.log("[LayoutGridViewModel] [\(playerID)] Setting focus on player from \(self.focusPlayerID)")
        
        // Remove focus from the old player.
        if focusPlayerIndex < playersToShow.count {
            playersToShow[focusPlayerIndex].toggleFocus(isFocused: false)
        }
        
        // Set focus on the new player.
        if let index = playersToShow.firstIndex(where: { $0.playerID == playerID }) {
            playersToShow[index].toggleFocus(isFocused: true)
            
            focusPlayerIndex = index
            focusPlayerID = playerID
        }
    }
    
    // Set full screen on the selected player.
    func setFullScreenPlayer(playerState: PlayerState) {
        
        if fullscreenPlayer?.playerID == playerState.playerID {
            // Exit full screen and unhide all players.
            for player in playersToShow {
                player.updateFullScreenStatus(isFullScreen: false)
                player.shouldBeHidden = false
            }
            
            fullscreenPlayer = nil
        } else {
            // Enter full screen and hide all other players.
            for player in playersToShow {
                if player.playerID != playerState.playerID {
                    player.updateFullScreenStatus(isFullScreen: false)
                    player.shouldBeHidden = true
                } else {
                    player.updateFullScreenStatus(isFullScreen: true)
                }
            }
            
            fullscreenPlayer = playerState
        }
    }
}
