/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays information about the currently selected artist.
*/

import MusicKit
import SwiftUI

/// A view that presents detailed information about a specific artist.
struct ArtistDetailView: View {
    
    // MARK: - Properties
    
    @State var artist: Artist
    
    let prominentAlbumsProperties: [MusicRelationshipProperty<Artist, Album>] = [
        .latestRelease,
        .featuredAlbums,
        .compilationAlbums
    ]
    
    private func items(for property: MusicRelationshipProperty<Artist, Album>) -> MusicItemCollection<Album>? {
        let items: MusicItemCollection<Album>?
        switch property {
            case .latestRelease:
                if let latestRelease = artist.latestRelease {
                    items = [latestRelease]
                } else {
                    items = nil
                }
            case .featuredAlbums:
                items = artist.featuredAlbums
            case .compilationAlbums:
                items = artist.compilationAlbums
            default:
                fatalError("Unexpected association property.")
        }
        return items
    }
    
    // MARK: - View
    
    var body: some View {
        content
            .navigationTitle(artist.name)
            .task {
                await loadDetailedArtist()
            }
    }
    
    private var content: some View {
        List {
            ForEach(prominentAlbumsProperties, id: \.propertyName) { prominentAlbumsProperty in
                if let albums = items(for: prominentAlbumsProperty), !albums.isEmpty {
                    MusicItemSection(fallbackTitle: "", items: albums) { album in
                        AlbumCell(album)
                    }
                }
            }
            
            if let musicVideos = artist.musicVideos, !musicVideos.isEmpty {
                MusicItemSection(title: "Music Videos", items: musicVideos) { musicVideo in
                    TrackCell(.musicVideo(musicVideo), from: artist)
                }
            }
            
            if let albums = artist.albums, !albums.isEmpty {
                MusicItemSection(title: "Albums", items: albums) { album in
                    AlbumCell(album)
                }
            }
            
            if let playlists = artist.playlists, !playlists.isEmpty {
                MusicItemSection(title: "Playlists", items: playlists) { playlist in
                    PlaylistCell(playlist)
                }
            }
        }
    }
    
    // MARK: - Updating with detailed artist information
    
    @MainActor
    private func loadDetailedArtist() async {
        do {
            let detailedArtist = try await artist.with([.albums, .musicVideos, .playlists] + prominentAlbumsProperties)
            self.artist = detailedArtist
        } catch {
            print("Failed to load additional content for \(artist) with error: \(error).")
        }
    }
}

// MARK: - Convenience extension for artist associations

extension MusicRelationshipProperty where Root == Artist, RelatedMusicItemType == Album {
    var propertyName: String {
        let propertyName: String
        switch self {
            case .latestRelease:
                propertyName = "latestRelease"
            case .featuredAlbums:
                propertyName = "featuredAlbums"
            case .compilationAlbums:
                propertyName = "compilationAlbums"
            default:
                fatalError("Unexpected association property.")
        }
        return propertyName
    }
}
