/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view for curator details.
*/

import MusicKit
import SwiftUI

/// A view that displays detailed information about a specific curator.
struct CuratorDetailView: View {
    
    // MARK: - Properties
    
    @State var curator: Curator
    
    // MARK: - View
    
    var body: some View {
        content
            .navigationTitle(curator.name)
            .task {
                await loadDetailedCurator()
            }
    }
    
    private var content: some View {
        List {
            if let playlists = curator.playlists {
                Section(header: Text("Playlists")) {
                    ForEach(playlists) { playlist in
                        PlaylistCell(playlist)
                    }
                }
            }
        }
    }
    
    // MARK: - Updating with detailed curator information
    
    @MainActor
    private func loadDetailedCurator() async {
        do {
            let detailedCurator = try await curator.with(.playlists)
            self.curator = detailedCurator
        } catch {
            print("Failed to load additional content for \(curator) with error: \(error).")
        }
    }
}
