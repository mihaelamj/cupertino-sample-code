/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays curator information.
*/

import MusicKit
import SwiftUI

/// A cell that displays curator information.
struct CuratorCell: View {
    
    // MARK: - Initialization
    
    init(_ curator: Curator) {
        self.curator = curator
    }
    
    // MARK: - Properties
    
    let curator: Curator
    
    // MARK: - View
    
    var body: some View {
        NavigationLink(destination: CuratorDetailView(curator: curator)) {
            MusicItemCell(
                artwork: curator.artwork,
                title: curator.name
            )
        }
    }
    
}
