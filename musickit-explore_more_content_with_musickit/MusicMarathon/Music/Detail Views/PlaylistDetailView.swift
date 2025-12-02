/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays detail information for a playlist.
*/

import MusicKit
import SwiftUI

/// A view that presents detailed information about a specific playlist.
struct PlaylistDetailView: View {
    
    // MARK: - Properties
    
    @State var playlist: Playlist
    @State var isShowingPlaylistPicker = false
    @State var itemToAdd: Track?
    var isLibrary: Bool
    
    // MARK: - View
    
    var body: some View {
        content
            .navigationTitle(playlist.name)
            .sheet(isPresented: $isShowingPlaylistPicker) {
                PlaylistPicker(currentItem: $itemToAdd, isShowingPlaylistPicker: $isShowingPlaylistPicker)
            }
            .task {
                await self.loadDetailedPlaylist()
            }
    }
    
    private var content: some View {
        List {
            header
                .listRowBackground(Color.clear)
            
            if let tracks = playlist.tracks {
                Section(header: Text("Tracks")) {
                    ForEach(tracks, id: \.self) { track in
                        TrackCell(track, from: playlist)
                            .contextMenu {
                                Button("Add to Playlist", action: {
                                    itemToAdd = track
                                    isShowingPlaylistPicker = true
                                })
                            }
                    }
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .center) {
            if let artwork = playlist.artwork {
                ArtworkImage(artwork, width: 320, height: 320)
                    .cornerRadius(8.0)
            }
            PlayButton(for: playlist)
        }
    }
    
    // MARK: - Updating with detailed playlist
    
    @MainActor
    private func loadDetailedPlaylist() async {
        do {
            let detailedPlaylist = try await playlist.with(.tracks, preferredSource: isLibrary ? .library : .catalog)
            playlist = detailedPlaylist
        } catch {
            print("Failed to load additional content for \(playlist) with error: \(error).")
        }
    }
}
