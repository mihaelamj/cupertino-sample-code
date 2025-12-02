/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell used to add songs to a playlist.
*/

import MusicKit
import SwiftUI

/// A cell that lets the user add tracks to a playlist.
struct AddToPlaylistCell: View {
    
    // MARK: - Properties
    
    @Binding var isShowingPlaylistPicker: Bool
    @Binding var selectedTrack: Track?
    let playlist: Playlist
    
    // MARK: - View
    
    var body: some View {
        Button(action: addItemToPlaylist) {
            MusicItemCell(title: playlist.name)
        }
    }
    
    func addItemToPlaylist() {
        Task {
            do {
                if let track = selectedTrack {
                    try await MusicLibrary.shared.add(track, to: playlist)
                } else {
                    print("Failed to add music item to playlist \(playlist) due to nil selected track.")
                }
                isShowingPlaylistPicker = false
            } catch {
                print("Failed to add music item \(String(describing: selectedTrack)) to playlist \(playlist) due to error: \(error).")
            }
        }
    }
}
