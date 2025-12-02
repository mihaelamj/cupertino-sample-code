/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that displays a dance video for the matched song.
*/

import AVKit
import SwiftUI

struct NowPlayingView: View {
    
    // MARK: View Constants
    private enum ViewConstants {
        static let videoPlayerAspectRatio: CGFloat = 16 / 9
        static let videoPlayerPosition: CGFloat = 2.0
        static let songDetailsSpacing: CGFloat = -4.0
        static let artworkBorderWidth: CGFloat = 2.0
        static let artworkTopPadding: CGFloat = -50.0
        static let artworkBottomPadding: CGFloat = -4.0
        static let artworkSize: CGFloat = 60.0
        static let artworkCornerRadius: CGFloat = 6.0
        static let nowPlayingText: String = "NOW PLAYING"
        static let nowPlayingTextWidth: CGFloat = 90.0
        static let nowPlayingTextPadding: CGFloat = 2.0
        static let nowPlayingTextCornerRadius: CGFloat = 5.0
        static let nowPlayingViewHiddenVerticalOffset: CGFloat = 300
        static let songTitleTopPadding: CGFloat = 24.0
        static let songTitleBottomPadding: CGFloat = 8.0
        static let curvedTopSideRectangleHeight: CGFloat = 200
        static let backButtonImageName: String = "chevron.backward"
        static let playerTimeScale: CMTimeScale = 60_000
        static let musicNoteImageName: String = "music.note"
        static let musicNoteImageWidth: CGFloat = 30.0
        static let musicNoteImageHeight: CGFloat = 28.0
        static let musicNoteImageBackgroundColor = Color(red: 14 / 255, green: 33 / 255, blue: 45 / 255)
    }
    
    // MARK: Properties
    @Binding var navigationPath: [NavigationPath]
    
    @StateObject var nowPlayingViewModel: NowPlayingViewModel
    private var currentPlaybackTime: CMTime {
        CMTime(
            seconds: matcher.currentMediaItem?.predictedCurrentMatchOffset ?? .zero,
            preferredTimescale: ViewConstants.playerTimeScale
        )
    }
    
    // MARK: Environment
    @EnvironmentObject private var matcher: Matcher
    @EnvironmentObject private var sceneHandler: SceneHandler
    
    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometryReader in
                VideoPlayerView(player: $nowPlayingViewModel.player)
                    .frame(width: geometryReader.size.height * ViewConstants.videoPlayerAspectRatio, height: geometryReader.size.height)
                    .position(x: geometryReader.size.width / ViewConstants.videoPlayerPosition,
                              y: geometryReader.size.height / ViewConstants.videoPlayerPosition)
            }
            ZStack(alignment: .top) {
                CurvedTopSideRectangle()
                VStack(spacing: ViewConstants.songDetailsSpacing) {
                    ZStack {
                        AsyncImage(url: matcher.currentMediaItem?.artworkURL) { image in
                            image
                                .resizable()
                                .mask(RoundedRectangle(cornerRadius: ViewConstants.artworkCornerRadius))
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ZStack {
                                RoundedRectangle(cornerRadius: ViewConstants.artworkCornerRadius)
                                    .foregroundColor(ViewConstants.musicNoteImageBackgroundColor)
                                Image(systemName: ViewConstants.musicNoteImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.musicNoteColor)
                                    .frame(width: ViewConstants.musicNoteImageWidth, height: ViewConstants.musicNoteImageHeight)
                            }
                        }
                        .frame(width: ViewConstants.artworkSize, height: ViewConstants.artworkSize)
                        RoundedRectangle(cornerRadius: ViewConstants.artworkCornerRadius)
                            .stroke(Color.appPrimary, lineWidth: ViewConstants.artworkBorderWidth)
                    }
                    .frame(width: ViewConstants.artworkSize + 2, height: ViewConstants.artworkSize + 2)
                    .padding(.top, ViewConstants.artworkTopPadding)
                    .padding(.bottom, ViewConstants.artworkBottomPadding)
                    Text(ViewConstants.nowPlayingText)
                        .font(.caption)
                        .fontWeight(.bold)
                        .frame(width: ViewConstants.nowPlayingTextWidth)
                        .padding(.all, ViewConstants.nowPlayingTextPadding)
                        .background(Color.appPrimary)
                        .mask(RoundedRectangle(cornerRadius: ViewConstants.nowPlayingTextCornerRadius))
                        .foregroundStyle(.black)
                    Text(matcher.currentMediaItem?.title ?? "")
                        .foregroundStyle(.white)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, ViewConstants.songTitleTopPadding)
                        .padding(.bottom, ViewConstants.songTitleBottomPadding)
                    Text(matcher.currentMediaItem?.artist ?? "")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
            .opacity(nowPlayingViewModel.showNowPlayingView ? 1 : .zero)
            .animation(.easeInOut(duration: 0.3), value: nowPlayingViewModel.showNowPlayingView)
            .frame(height: ViewConstants.curvedTopSideRectangleHeight)
        }
        .onTapGesture {
            nowPlayingViewModel.updateNowPlayingViewVisibility()
        }
        .onChange(of: nowPlayingViewModel.playbackComplete, {
            
            guard nowPlayingViewModel.playbackComplete else { return }
            matcher.stopRecording()
            matcher.endSession()
            navigationPath.append(.danceCompletionView)
        })
        .onChange(of: matcher.currentMatchResult, {
            guard matcher.currentMatchResult != nil else { return }
            nowPlayingViewModel.setupPlayback(at: currentPlaybackTime)
        })
        .onChange(of: sceneHandler.state) { _, newSceneState in
            switch newSceneState {
            case .foreground:
                if nowPlayingViewModel.shouldMatchToSyncPlayback {
                    // Rematch to sync video with external playback of song.
                    Task { await matcher.match() }
                }
                nowPlayingViewModel.viewMovedToForeground()
            case .background:
                nowPlayingViewModel.viewMovedToBackground()
            }
        }
        .edgesIgnoringSafeArea(.vertical)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    stopPlayback()
                    navigationPath.removeLast()
                } label: {
                    Image(systemName: ViewConstants.backButtonImageName)
                        .fontWeight(.bold)
                        .font(.title2)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.white, Color.appTertiary)
                        .symbolVariant(.circle.fill)
                }
                .buttonStyle(.borderless)
            }
        }
        .toolbarRole(.navigationStack)
        .onAppear {
            nowPlayingViewModel.setupPlayback(at: currentPlaybackTime)
        }
        .task {
            if let mediaItem = matcher.currentMediaItem {
                await nowPlayingViewModel.addMediaItem(mediaItem)
            }
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    private func stopPlayback() {
        nowPlayingViewModel.stopPlayback()
        matcher.stopRecording()
        matcher.endSession()
    }
}

struct NowPlayingView_Previews: PreviewProvider {
    
    @State private static var path: [NavigationPath] = []
    static var previews: some View {
        NowPlayingView(navigationPath: $path, nowPlayingViewModel: NowPlayingViewModel(player: AVPlayer()))
            .environmentObject(Matcher())
            .environmentObject(SceneHandler())
    }
}
