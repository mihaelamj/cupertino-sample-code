/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A player that handles remote commands.
*/

import MediaPlayer

/// A type that reports remote events the player receives.
///
/// Types that conform to this protocol want to receive updates about the remote events the player receives.
protocol RemoteEventsPlayerReporting: AnyObject {
    /// Called when the player receives a remote event.
    ///
    /// - Parameter remoteEvent: The `RemoteEvent` the player received.
    func playerReceived(remoteEvent: RemoteEvent)
}

class RemoteEventsPlayer {

    private let audioName = "SampleAudio"
    private let audioURL = Bundle.main.url(forResource: "SampleAudio", withExtension: ".m4a")!

    // Default rate for playing state.
    private let defaultPlaybackRate: Float = 1.0
    
    // Mute by default.
    private let defaultVolume: Float = 0.0

    let player: AVQueuePlayer

    weak var delegate: RemoteEventsPlayerReporting?

    private var statusObserver: NSKeyValueObservation?

    init() {
        let sampleAudioItem = AVPlayerItem(url: audioURL)
        player = AVQueuePlayer(items: [sampleAudioItem])
        player.volume = defaultVolume

        guard player.currentItem != nil else { return }

        statusObserver = player.observe(\.currentItem?.status) { [weak self] _, _ in
            guard let self = self,
                  self.player.currentItem?.status == .readyToPlay else { return }

            // Start playback.
            self.player.play()

            // When the item is ready to play, update the Now Playing info for
            // the new item and set up the supported remote commands.
            self.handleNowPlayingItemChange()
            self.setupSupportedRemoteCommands()
        }
    }

    // MARK: Public methods

    /// Prepares the player for dismissal.
    func tearDown() {
        statusObserver?.invalidate()
        statusObserver = nil

        player.pause()
        player.removeAllItems()

        tearDownSupportedRemoteCommands()

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Prepares the player for an app background event.
    func prepareForAppBackground() {
        tearDownSupportedRemoteCommands()
    }

    /// Prepares the player for an app foreground event.
    func prepareForAppForeground() {
        setupSupportedRemoteCommands()
        // Play the content if it's not currently playing.
        player.play()
    }

    // MARK: Now Playing Info updates

    /// - Tag: handleNowPlayingItemChange
    /// Updates the Now Playing info for the new item.
    private func handleNowPlayingItemChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let currentItem = self.player.currentItem else { return }

            let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
            var nowPlayingInfo = [String: Any]()

            nowPlayingInfo[MPMediaItemPropertyTitle] = self.audioName
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = currentItem.duration.seconds

            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
            nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] = self.audioURL
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate
            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = self.defaultPlaybackRate
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime().seconds
            // Set any other property applicable to your application.

            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }

    // MARK: Remote command center

    /// The list of remote commands that the player supports.
    private var supportedRemoteCommands: [RemoteCommand] {
        // In this sample, the remote events player supports all available
        // remote commands.
        RemoteCommand.allCases
    }

    /// Sets up the supported remote commands.
    private func setupSupportedRemoteCommands() {
        supportedRemoteCommands.forEach { remoteCommand in
            // Remove each target before you add a new one.
            remoteCommand.mediaRemoteCommand.removeTarget(nil)
            remoteCommand.mediaRemoteCommand.addTarget {
                self.handle(command: remoteCommand, withCommandEvent: $0)
            }
        }
    }

    /// Tears down supported remote commands.
    private func tearDownSupportedRemoteCommands() {
        supportedRemoteCommands.forEach { $0.mediaRemoteCommand.removeTarget(nil) }
    }

    /// Handles a received command previously registered with the remote command center.
    ///
    /// - Parameter command: The `RemoteCommand` triggered.
    /// - Parameter commandEvent: The `MPRemoteCommandEvent` received.
    private func handle(command: RemoteCommand, withCommandEvent commandEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        switch command {

            // Playback commands.
            // Also implement the play/pause functionality in the
            // `setupGestureRecognizers()` method in `RemoteEventsViewController`.
        case .play:
            delegate?.playerReceived(remoteEvent: .play)
        case .pause:
            delegate?.playerReceived(remoteEvent: .pause)
        case .togglePlayPause:
            delegate?.playerReceived(remoteEvent: .playPause)
        case .stop:
            delegate?.playerReceived(remoteEvent: .stop)

            // Navigating between tracks commands.
        case .nextTrack:
            delegate?.playerReceived(remoteEvent: .nextTrack)
        case .previousTrack:
            delegate?.playerReceived(remoteEvent: .previousTrack)
        case .changeRepeatMode, .changeShuffleMode:
            // Implement if applicable to your application.
            print("Navigating Between tracks commands")

        // Navigating track content commands.
        case .changePlaybackRate:
            guard let event = commandEvent as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            delegate?.playerReceived(remoteEvent: (event.playbackRate > 0) ? .fastForward : .rewind)

        case .seekBackward, .seekForward:
            break
        case .skipBackward:
            delegate?.playerReceived(remoteEvent: .skipBackward)

        case .skipForward:
            delegate?.playerReceived(remoteEvent: .skipForward)

        case .changePlaybackPosition:
            break

        // Rating media item commands.
        case .rating, .like, .dislike:
            // Implement if applicable to your app.
            print("Rating Media Items commands")

        // Bookmark media item command.
        case .bookmark:
            // Implement if applicable to your app.
            print("Bookmarking Media Items")

        // Enabling language option commands.
        case .enableLanguageOption, .disableLanguageOption:
            // Implement if applicable to your app.
            print("Language Option commands")
        }

        return .success
    }
}
