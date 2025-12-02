/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that describes player state.
*/

import AVFoundation
import SwiftUI

@MainActor
@Observable
final class PlayerModel {
    let player: AVPlayer

    private(set) var playerItem: AVPlayerItem?
    private(set) var timeControlStatus: AVPlayer.TimeControlStatus?
    private(set) var didPlayToEndTime = false
    private var readiness = PlaybackReadiness.default
    private var playerObservationToken: NSKeyValueObservation?
    private var readyToPlayObservation: NSKeyValueObservation?

    // MARK: Internal behavior
    
    init(player: AVPlayer) {
        self.player = player
        registerPlayerObservers()
    }
    
    var isPlaying: Bool {
        timeControlStatus == .playing
    }

    var isReadyToPlay: Bool {
        readiness.isReady
    }

    func loadItem(_ item: VideoModel) {
        reset()

        let asset = AVURLAsset(url: item.url)
        playerItem = AVPlayerItem(asset: asset)
        readyToPlayObservation = playerItem?.observe(\.status) { avPlayerItem, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.readiness = self.readiness.with(isPlayerItemReadyToPlay: (avPlayerItem.status == .readyToPlay))
            }
        }
        player.replaceCurrentItem(with: playerItem)
    }

    func pause() {
        player.pause()
    }
    
    func play() {
        player.play()
    }
    
    func stop() {
        player.pause()
        didPlayToEndTime = true
    }

    func updateVideoRenderingStatus(isVideoReadyToRender: Bool) {
        readiness = readiness.with(isVideoReadyToRender: isVideoReadyToRender)
    }

    // MARK: Private behavior
    
    private func observeItemPlayedToEnd() {
        Task { @MainActor [weak self] in
            for await _ in NotificationCenter.default.notifications(named: .AVPlayerItemDidPlayToEndTime) {
                self?.didPlayToEndTime = true
            }
        }
    }
    
    private func observeTimeControlStatus() {
        playerObservationToken = player.observe(\.timeControlStatus) { observed, _ in
            Task { @MainActor [weak self] in
                self?.timeControlStatus = observed.timeControlStatus
            }
        }
    }
    
    private func registerPlayerObservers() {
        observeItemPlayedToEnd()
        observeTimeControlStatus()
    }

    private func reset() {
        readiness = .default
        didPlayToEndTime = false
    }
}
