/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that implements a mini music player.
*/

import MusicKit
import SwiftUI

/// A view that implements a music player at the bottom of another view.
struct MiniPlayer: View {
    
    // MARK: - Properties
    
    @ObservedObject var playbackQueue = ApplicationMusicPlayer.shared.queue
    @ObservedObject private var musicPlayer = MarathonMusicPlayer.shared
    @State var isShowingNowPlaying = false
    @State var isShowingMusic = false
    
    // MARK: - View
    
    var body: some View {
        content
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .sheet(isPresented: $isShowingNowPlaying) {
                NowPlayingView(playbackQueue: playbackQueue)
            }
            .sheet(isPresented: $isShowingMusic) {
                MusicView()
            }
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.systemBackground))
                    .padding([.leading, .trailing])
                    .standardShadow()
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if let currentPlayerEntry = playbackQueue.currentEntry {
            HStack {
                Button(action: handleTap) {
                    MusicItemCell(
                        artwork: currentPlayerEntry.artwork,
                        artworkSize: 64.0,
                        artworkCornerRadius: 12.0,
                        title: currentPlayerEntry.title,
                        subtitle: currentPlayerEntry.subtitle,
                        subtitleVerticalOffset: -4.0
                    )
                }
                Spacer()
                pauseButton
                seeQueueView
            }
            .padding(.leading, 24)
            .padding(.trailing, 24)
        } else {
            Button(action: handleTap) {
                MusicItemCell(
                    artwork: nil,
                    artworkSize: 64.0,
                    artworkCornerRadius: 12.0,
                    title: "Nothing Playing",
                    subtitle: "Click here to explore music content",
                    subtitleVerticalOffset: -4.0
                )
            }
        }
    }
    
    var pauseButton: some View {
        Button(action: pausePlay) {
            Image(systemName: (musicPlayer.isPlaying ? "pause.fill" : "play.fill"))
                .foregroundColor(.black)
        }
    }
    
    var seeQueueView: some View {
        Button {
            isShowingNowPlaying = true
        } label: {
            Image(systemName: "list.bullet")
                .font(.system(size: 18))
                .foregroundColor(.black)
        }
    }
    
    // MARK: - Methods
    
    private func pausePlay() {
        musicPlayer.togglePlaybackStatus()
    }
    
    private func handleTap() {
        isShowingMusic = true
    }
}
