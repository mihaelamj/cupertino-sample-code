/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays information about the currently playing song.
*/

import MusicKit
import SwiftUI

/// A SwiftUI view that displays information about the currently playing song and queue.
struct NowPlayingView: View {
    
    // MARK: - Properties
    
    @ObservedObject var playbackQueue: ApplicationMusicPlayer.Queue
    
    // MARK: - View
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Now Playing")
        }
    }
    
    @ViewBuilder
    private var content: some View {
        list(for: playbackQueue)
    }
    
    private func list(for playbackQueue: ApplicationMusicPlayer.Queue) -> some View {
        List {
            ForEach(playbackQueue.entries) { entry in
                MusicItemCell(
                    artwork: entry.artwork,
                    artworkSize: 44,
                    artworkCornerRadius: 4,
                    title: entry.title,
                    subtitle: entry.subtitle,
                    subtitleVerticalOffset: -2.0
                )
            }
            .onDelete { offsets in
                playbackQueue.entries.remove(atOffsets: offsets)
            }
            .onMove { source, destination in
                playbackQueue.entries.move(fromOffsets: source, toOffset: destination)
            }
        }
        .animation(.default, value: playbackQueue.entries)
        .toolbar {
            EditButton()
        }
    }
    
}
