/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that describes player state.
*/

import AVFoundation
import SwiftUI

/// A model that describes player state.
@MainActor
@Observable
final class PlayerModel {
    /// Represents the path to sample video contained within the app bundle.
    private static let resourceURL = Bundle.main.bundleURL.appendingPathComponent("sample.mov")
    
    /// Describes potential playback states.
    enum PlayerState {
        /// Indicates that the player is currently loading.
        case loading

        /// Indicates that the player failed to load the video asset.
        case loadingFailed

        /// Indicates that the player successfully loaded the asset.
        case loaded

        /// Indicates that playback is currently in progress.
        case playing

        /// Indicates that playback has stopped.
        case stopped

        /// By default, the initial player state is `loading`.
        static let `default` = PlayerState.loading
    }

    /// The current state of the player.
    private var state = PlayerState.default
    
    /// An instance of a looping video player.
    private let player: LoopingVideoPlayer
    
    /// The underlying video renderer.
    var videoRenderer: AVSampleBufferVideoRenderer {
        player.videoRenderer
    }

    // MARK: Internal behavior

    /// Default, no-arg initializer.
    init() {
        player = LoopingVideoPlayer(assetURL: Self.resourceURL)
    }
    
    /// Begin loading the player for playback.
    func load() async {
        do {
            try await player.load()
            state = .loaded
        } catch {
            debugPrint("Loading failed: \(error.localizedDescription)")
            state = .loadingFailed
        }
    }
    
    /// Begin playback.
    func play() {
        guard isReadyToPlay, !isPlaying else {
            debugPrint("Unable to play, current state: \(state)")
            return
        }

        player.play()
        state = .playing
    }
    
    /// Stop playback.
    func stop() {
        player.stop()
        state = .stopped
    }
    
    /// Returns `true` if the player is ready to play; `false` otherwise.
    var isReadyToPlay: Bool {
        state == .loaded
    }

    // MARK: Private behavior

    /// Returns `true` if the player is playing; `false` otherwise.
    private var isPlaying: Bool {
        state == .playing
    }
}
