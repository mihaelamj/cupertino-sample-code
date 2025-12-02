/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that allows playlist creation.
*/

import MusicKit
import SwiftUI

/// A cell that allows the user to create a new playlist.
struct CreatePlaylistCell: View {
    
    // MARK: - Properties
    
    @Binding var isShowingPlaylistPicker: Bool
    @Binding var currentItem: Track?
    
    // MARK: - View
    
    var body: some View {
        Button(action: createPlaylist) {
            VStack {
                Text("Create Playlist")
                    .fontWeight(.semibold)
            }
        }
    }
    
    // MARK: - Methods
    
    private func createPlaylist() {
        Task {
            do {
                let tracks: [Track]
                if let track = currentItem {
                    tracks = [track]
                } else {
                    tracks = []
                }
                try await MusicLibrary.shared.createPlaylist(
                    name: "Music Marathon Playlist",
                    description: "A playlist created through the Music Marathon app.",
                    items: tracks
                )
                isShowingPlaylistPicker = false
            } catch {
                print("Failed to create a playlist due to error: \(error).")
            }
        }
    }
}
