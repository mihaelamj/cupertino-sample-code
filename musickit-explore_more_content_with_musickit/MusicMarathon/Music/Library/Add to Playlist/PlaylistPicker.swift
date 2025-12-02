/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that allows playlist selection.
*/

import MusicKit
import SwiftUI

/// A view that displays the playlists in the user's library. It also allows additions to that playlist.
struct PlaylistPicker: View {
    
    // MARK: - Properties
    
    @State private var response: MusicLibraryResponse<Playlist>? = nil
    @Binding var currentItem: Track?
    @Binding var isShowingPlaylistPicker: Bool
    
    // MARK: - View
    
    var body: some View {
        content
            .navigationTitle("Add to Playlist")
            .task {
                await loadLibraryPlaylists()
            }
    }
    
    private var content: some View {
        List {
            CreatePlaylistCell(isShowingPlaylistPicker: $isShowingPlaylistPicker, currentItem: $currentItem)
            if let response = response {
                ForEach(response.items) { playlist in
                    AddToPlaylistCell(
                        isShowingPlaylistPicker: $isShowingPlaylistPicker,
                        selectedTrack: $currentItem,
                        playlist: playlist
                    )
                }
            }
        }
    }
    
    // MARK: - Methods
    
    @MainActor
    private func loadLibraryPlaylists() async {
        do {
            let request = MusicLibraryRequest<Playlist>()
            let response = try await request.response()
            self.response = response
        } catch {
            print("Failed to load library playlists due to error: \(error).")
        }
    }
}
