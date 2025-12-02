/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays detail album information.
*/

import MusicKit
import SwiftUI

/// A view that displays detailed information about a specific album.
struct AlbumDetailView: View {
    
    // MARK: - Properties
    
    @State var album: Album
    
    // MARK: - View
    
    var body: some View {
        List {
            header
                .listRowBackground(Color.clear)
            
            if let tracks = album.tracks {
                Section(header: Text("Tracks")) {
                    ForEach(tracks) { track in
                        TrackCell(track, from: album)
                    }
                }
            }
            
            if let relatedAlbums = album.relatedAlbums, !relatedAlbums.isEmpty {
                Section(header: Text("Related Albums")) {
                    ForEach(relatedAlbums) { album in
                        AlbumCell(album)
                    }
                }
            }
        }
        .navigationTitle(album.title)
        .task {
            await loadDetailedAlbum()
        }
    }
    
    private var header: some View {
        VStack {
            if let artwork = album.artwork {
                ArtworkImage(artwork, width: Self.artworkWidth)
                    .cornerRadius(Self.artworkCornerRadius)
            }
            Text(album.artistName)
                .font(.title3.bold())
            PlayButton(for: album)
        }
    }
    
    // MARK: - Methods
    
    @MainActor
    private func loadDetailedAlbum() async {
        do {
            let detailedAlbum = try await album.with(.tracks, .relatedAlbums)
            album = detailedAlbum
        } catch {
            print("Failed to load additional content for \(album) with error: \(error).")
        }
    }
    
    // MARK: - Constants
    
    private static let artworkWidth = 320.0
    private static let artworkCornerRadius = 8.0
    
}
