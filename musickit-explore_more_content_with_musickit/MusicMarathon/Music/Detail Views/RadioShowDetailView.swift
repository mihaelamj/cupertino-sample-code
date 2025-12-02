/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays radio show details.
*/

import MusicKit
import SwiftUI

/// A view that displays detailed information about a specific radio show.
struct RadioShowDetailView: View {
    
    // MARK: - Properties
    
    @State var radioShow: RadioShow
    
    // MARK: - View
    
    var body: some View {
        content
            .navigationTitle(radioShow.name)
            .task {
                await loadDetailedRadioShow()
            }
    }
    
    private var content: some View {
        List {
            if let playlists = radioShow.playlists {
                Section(header: Text("Playlists")) {
                    ForEach(playlists) { playlist in
                        PlaylistCell(playlist)
                    }
                }
            }
        }
    }
    
    // MARK: - Updating with detailed radio show
    
    @MainActor
    private func loadDetailedRadioShow() async {
        do {
            let detailedRadioShow = try await radioShow.with(.playlists)
            self.radioShow = detailedRadioShow
        } catch {
            print("Failed to load additional content for \(radioShow) with error: \(error).")
        }
    }
}
