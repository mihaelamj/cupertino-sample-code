/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays music track information.
*/

import MusicKit
import SwiftUI

/// A  cell that displays music track data.
struct TrackCell: View {
    
    // MARK: - Initialization
    
    init(_ track: Track) {
        self.track = track
        self.trackList = nil
        self.parentCollectionID = nil
        self.parentCollectionArtistName = nil
        self.shouldDisplayArtwork = true
    }
    
    init(_ track: Track, from artist: Artist) {
        self.track = track
        self.trackList = nil
        self.parentCollectionID = artist.id
        self.parentCollectionArtistName = artist.name
        self.shouldDisplayArtwork = true
    }
    
    init(_ track: Track, from album: Album) {
        self.track = track
        self.trackList = album.tracks
        self.parentCollectionID = album.id
        self.parentCollectionArtistName = album.artistName
        self.shouldDisplayArtwork = false
    }
    
    init(_ track: Track, from playlist: Playlist) {
        self.track = track
        self.trackList = playlist.tracks
        self.parentCollectionID = playlist.id
        self.parentCollectionArtistName = playlist.curatorName
        self.shouldDisplayArtwork = true
    }
    
    // MARK: - Properties
    
    let track: Track
    let trackList: MusicItemCollection<Track>?
    let parentCollectionID: MusicItemID?
    let parentCollectionArtistName: String?
    let shouldDisplayArtwork: Bool
    
    private var subtitle: String {
        var subtitle = ""
        if track.artistName != parentCollectionArtistName {
            subtitle = track.artistName
        }
        return subtitle
    }
    
    // MARK: - View
    
    var body: some View {
        Button(action: { MarathonMusicPlayer.shared.play(track, in: trackList, with: parentCollectionID) }) {
            MusicItemCell(
                title: track.title,
                subtitle: subtitle
            )
            .frame(minHeight: Self.minimumHeight)
        }
    }
    
    // MARK: - Constants
    
    private static let minimumHeight: CGFloat? = 50
    
}
