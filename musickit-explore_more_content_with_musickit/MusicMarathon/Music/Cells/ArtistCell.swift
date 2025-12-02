/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays artist information.
*/

import MusicKit
import SwiftUI

/// A cell that displays artist information..
struct ArtistCell: View {
    
    // MARK: - Initialization
    
    init(_ artist: Artist) {
        self.artist = artist
    }
    
    // MARK: - Properties
    
    let artist: Artist
    
    // MARK: - View
    
    var body: some View {
        NavigationLink(destination: ArtistDetailView(artist: artist)) {
            MusicItemCell(
                artwork: nil,
                title: artist.name,
                subtitle: ""
            )
        }
    }
    
}
