/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model that drives the video playing UI.
*/

import AVKit
import ShazamKit

final class NowPlayingViewModel: ObservableObject {
    
    private enum Constants {
        static let playerTimeScale: CMTimeScale = 60_000
    }
    
    @Published var player: AVPlayer
    @Published var showNowPlayingView: Bool = true
    @Published var playbackComplete: Bool = false
    var shouldMatchToSyncPlayback: Bool {
        backgroundDate != nil
    }
    
    private var nowPlayingVisibilityTimer: Timer?
    private var updatingPlaybackTime: CMTime?
    private var backgroundDate: Date?
    
    init(player: AVPlayer) {
        self.player = player
        
        NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification,
                                                object: player.currentItem,
                                                 queue: OperationQueue.main,
                                                 using: { [weak self] _ in
            self?.playbackComplete = true
        })
        
        hideNowPlayingView()
    }
    
    func setupPlayback(at time: CMTime) {
        
        player.isMuted = true
        player.play()
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        updatingPlaybackTime = time
    }
    
    func stopPlayback() {
        
        player.pause()
        player.rate = .zero
        player.replaceCurrentItem(with: nil)
    }
    
    func addMediaItem(_ mediaItem: SHMediaItem) async {
        
        do {
            try await SHLibrary.default.addItems([mediaItem])
        } catch {
            print("Failed to add media item to Shazam library. Error \(error.localizedDescription)")
        }
    }
    
    func viewMovedToForeground() {
        
        guard let backgroundDate else {
            return
        }
    
        // Restart playback of video after app moves to foreground.
        let elapsedTimeSinceBackground = Date.now.timeIntervalSince(backgroundDate)
        let newVideoPlayerTime = CMTime(
            seconds: elapsedTimeSinceBackground + (updatingPlaybackTime?.seconds ?? .zero),
            preferredTimescale: Constants.playerTimeScale
        )
        setupPlayback(at: newVideoPlayerTime)
        self.backgroundDate = nil
    }
    
    func viewMovedToBackground() {
        
        backgroundDate = Date.now
        updatingPlaybackTime = player.currentTime()
    }
    
    func updateNowPlayingViewVisibility() {
        
        nowPlayingVisibilityTimer?.invalidate()
        showNowPlayingView.toggle()
        
        guard showNowPlayingView else { return }
        hideNowPlayingView()
    }
    
    private func hideNowPlayingView() {
        
        // Hide the overlay of currently playing song on the video player.
        nowPlayingVisibilityTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false, block: { [weak self] _ in
            
            self?.showNowPlayingView = false
        })
    }
}
