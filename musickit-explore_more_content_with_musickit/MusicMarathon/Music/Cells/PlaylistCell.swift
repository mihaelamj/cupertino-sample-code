/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays playlist information.
*/

import MusicKit
import SwiftUI

/// A  cell that displays a playlist.
struct PlaylistCell: View {
    
    // MARK: - Initialization
    
    init(_ playlist: Playlist, isLibrary: Bool = false) {
        self.playlist = playlist
        self.isLibrary = isLibrary
    }
    
    // MARK: - Properties
    
    let playlist: Playlist
    let isLibrary: Bool
    
    // MARK: - View
    
    var body: some View {
        NavigationLink(destination: PlaylistDetailView(playlist: playlist, isLibrary: isLibrary)) {
            MusicItemCell(
                artwork: playlist.artwork,
                title: playlist.name,
                subtitle: (playlist.curatorName ?? "")
            )
        }
    }
    
}
