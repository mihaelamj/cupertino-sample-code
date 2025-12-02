/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell view for lists of `Album` items.
*/

import MusicKit
import SwiftUI

/// `AlbumCell` is a view to use in a SwiftUI `List` to represent an `Album`.
struct AlbumCell: View {
    
    // MARK: - Object lifecycle
    
    init(_ album: Album) {
        self.album = album
    }
    
    // MARK: - Properties
    
    let album: Album
    
    // MARK: - View
    
    var body: some View {
        NavigationLink(destination: AlbumDetailView(album)) {
            MusicItemCell(
                artwork: album.artwork,
                title: album.title,
                subtitle: album.artistName
            )
        }
    }
}
