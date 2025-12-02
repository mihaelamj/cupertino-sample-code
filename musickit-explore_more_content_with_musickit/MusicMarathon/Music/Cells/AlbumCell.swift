/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays album information.
*/

import MusicKit
import SwiftUI

/// A cell that displays album data.
struct AlbumCell: View {
    
    // MARK: - Initialization
    
    init(_ album: Album) {
        self.album = album
    }
    
    // MARK: - Properties
    
    let album: Album
    
    // MARK: - View
    
    var body: some View {
        NavigationLink(destination: AlbumDetailView(album: album)) {
            MusicItemCell(
                artwork: album.artwork,
                title: album.title,
                subtitle: album.artistName
            )
        }
    }
}

