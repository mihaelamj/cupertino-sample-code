/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom player.
*/

import MediaPlayer

/// A type that provides textual feedback to report changes in the custom player.
///
/// Types that conform to this protocol want to receive updates from the custom player.
protocol CustomPlayerReporting: AnyObject {

    /// Called when the player receives an event, remote command, or when it's changed its state.
    ///  Types that conform to this protocol can use this method to present feedback on screen of what
    ///  happened in the custom player.
    ///
    /// - Parameter feedback: A text representing the action that happened in the player.
    /// - Parameter feedbackType: A `CustomPlayerFeedbackType` value indicating the type
    ///  of feedback the player received.
    func reportFeedback(_ feedback: String, withFeedbackType feedbackType: CustomPlayerFeedbackType)
}

class CustomPlayer {

    private var playerState: CustomPlayerState = .stopped // Default to stopped state

    let player: AVQueuePlayer

    weak var delegate: CustomPlayerReporting?

    // Private observers.
    private var rateObserver: NSKeyValueObservation?
    private var statusObserver: NSKeyValueObservation?

    init() {
        player = AVQueuePlayer(items: TVSchedule.shared.playerItems)

        guard player.currentItem != nil else { return }

        statusObserver = player.observe(\.currentItem?.status, options: .initial) { [weak self] _, _ in
            guard let self = self,
                  self.player.currentItem?.status == .readyToPlay else { return }

            // When the item is ready to play, update the Now Playing info for
            // the new item, set up the rate observer to keep track of rate
            // changes, and set up the supported remote commands.
            self.handleNowPlayingItemChange()
            self.setupRateObserver()
            self.setupSupportedRemoteCommands()

            // Start playback.
            self.play()
        }
    }

    /// Sets up the rate observer to keep track of the rate changes in the player.
    private func setupRateObserver() {
        rateObserver?.invalidate()
        rateObserver = player.observe(\.rate) { [weak self] _, _ in
            guard let self = self else { return }
            // Whenever a rate change is observed, update the NowPlaying Info
            // and local player state.
            self.handlePlaybackChange()
            self.updatePlayerState()
        }
    }

    /// The current program that the custom player is playing.
    private var currentProgram: Program? {
        let currentItemsCount = player.items().count
        guard currentItemsCount > 0 else { return nil }

        let channels = TVSchedule.shared.channels
        let currentChannelIndex = channels.count - currentItemsCount

        return TVSchedule.shared.channels[currentChannelIndex].currentProgram
    }

    // MARK: Public methods

    /// Prepares the custom player for dismissal.
    func tearDown() {
        statusObserver?.invalidate()
        statusObserver = nil
        rateObserver?.invalidate()
        rateObserver = nil

        player.pause()
        player.removeAllItems()

        playerState = .stopped

        tearDownSupportedRemoteCommands()

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Transmits a remote event received by the controller to the custom player.
    ///
    /// - Parameter remoteEvent: The `RemoteEvent` received by the controller.
    func remoteEventReceived(_ remoteEvent: RemoteEvent) {
        var additionalInfo: String = ""

        switch remoteEvent {
        case .select, .playPause:
            togglePlayPause()
            // No need to report the event because player state updates report
            // play/pause and select events.

        case .channelUp:
            nextTrack()
            if let currentProgram {
                additionalInfo = currentProgram.title
            }
            reportRemoteEventReceived(remoteEvent, withAdditionalInfo: additionalInfo)

        case .channelDown:
            previousTrack()
            if let currentProgram {
                additionalInfo = currentProgram.title
            }
            reportRemoteEventReceived(remoteEvent, withAdditionalInfo: additionalInfo)

        case .swipeUp, .swipeDown, .swipeLeft, .swipeRight:
            // Report the received event because the player doesn't have a swipe
            // action set.
            reportRemoteEventReceived(remoteEvent)

        case .dPadUp, .dPadDown:
            // Report the received event because the player doesn't receive a
            // D-pad up or down action.
            reportRemoteEventReceived(remoteEvent)

        case .dPadLeft, .dPadRight:
            handlePlayerBehaviorForDPadKeyPress(remoteEvent)

        default:
            // The player handles all other events.
            break
        }
    }

    /// Handles the custom player behavior when a supported D-pad key is pressed.
    ///
    /// Only a D-pad left and right key press affects the behavior of the custom player.
    ///
    /// - Parameter dPadKeyPressed: A `RemoteEvent` representing the D-pad key pressed.
    /// - Parameter isLongPress: A Boolean value that  indicates whether the view receives a
    /// D-pad key long press. If not set to `true`, it considers the press to be a short press by default.
    func handlePlayerBehaviorForDPadKeyPress(_ dPadKeyPressed: RemoteEvent, isLongPress: Bool = false) {
        guard dPadKeyPressed == .dPadLeft || dPadKeyPressed == .dPadRight else { return }

        // If the player is currently in fast forward or rewind mode (trick
        // play), the D-pad key press increases or decreases the fast forward or
        // rewind speed.
        let isTrickPlayMode = playerState == .fastForwarding || playerState == .rewinding
        if isTrickPlayMode {
            updateTrickPlayMode(withDPadKeyPressed: dPadKeyPressed)
            return
        }

        switch dPadKeyPressed {
        case .dPadLeft:
            // A D-pad left key long press triggers rewind mode.
            if isLongPress {
                triggerTrickPlayMode(.rewind)
                return
            }

            // A D-pad left key short press maps to skipBackward and skips 10
            // seconds backwards.
            skipBackward(by: skipInterval)
            let skipBackwardIntervalFeedback = "-\(Int(skipInterval))s" // -10s
            reportRemoteEventReceived(.skipBackward, withAdditionalInfo: skipBackwardIntervalFeedback)

        case .dPadRight:
            // A D-pad right key long press triggers fast forward mode.
            if isLongPress {
                triggerTrickPlayMode(.fastForward)
                return
            }

            // A D-pad right key short press maps to a skipForward and it skips
            // 10 seconds forward.
            skipForward(by: skipInterval)
            let skipForwardIntervalFeedback = "+\(Int(skipInterval))s" // +10s
            reportRemoteEventReceived(.skipForward, withAdditionalInfo: skipForwardIntervalFeedback)

        default:
            break
        }
    }

    /// Prepares the player for an app background event.
    func prepareForAppBackground() {
        tearDownSupportedRemoteCommands()
    }

    /// Prepares the player for an app foreground event.
    func prepareForAppForeground() {
        setupSupportedRemoteCommands()
        // Play the content if it's not currently playing.
        play()
    }

    // MARK: Now Playing Info updates

    /// Updates the Now Playing info for the new item.
    private func handleNowPlayingItemChange() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self,
                  let currentItem = self.player.currentItem,
                  let currentProgram = self.currentProgram else { return }

            var nowPlayingInfo = [String: Any]()

            nowPlayingInfo[MPMediaItemPropertyTitle] = currentProgram.title
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = currentItem.duration.seconds
            nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = currentProgram.isLive
            nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] = currentProgram.playlistURL
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = self.player.rate
            nowPlayingInfo[MPNowPlayingInfoPropertyDefaultPlaybackRate] = self.defaultPlaybackRate
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.player.currentTime().seconds

            // Set any other properties that are applicable to your application.

            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    /// Handles playback change events in the custom player.
    ///
    /// Updates the playback information for the current `AVPlayerItem` in the custom player.
    private func handlePlaybackChange() {
        DispatchQueue.main.async { [weak self] in
            guard let player = self?.player else { return }

            let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
            var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo ?? [String: Any]()

            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
            // Set any other properties that are applicable to your application.

            nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
        }
    }

    // MARK: Fast forward/rewind (trick play) related methods

    /// Triggers the trick play mode (fast forward or rewind) in the custom player.
    ///
    /// - Parameter trickPlayMode: A `TrickPlayMode` value that indicates whether the player
    /// will begin fast forwarding or rewinding.
    private func triggerTrickPlayMode(_ trickPlayMode: TrickPlayMode) {
        let supportedRates = trickPlayMode == .fastForward ? fastForwardSupportedRates : rewindSupportedRates
        guard let firstRate = supportedRates.first else { return }
        updatePlaybackRate(to: firstRate)
    }

    /// Updates the trick play mode with a D-pad key press received.
    ///
    /// Only a D-pad left and right key press updates the trick play mode.
    ///
    /// - Parameter dPadKeyPressed: A `RemoteEvent` indicating
    /// the D-pad key pressed.
    private func updateTrickPlayMode(withDPadKeyPressed dPadKeyPressed: RemoteEvent) {
        // Only a D-pad left and right press updates the trick play mode.
        guard dPadKeyPressed == .dPadLeft || dPadKeyPressed == .dPadRight else { return }

        let isPlayerInRewindMode = playerState == .rewinding
        let isPlayerInFastForwardMode = playerState == .fastForwarding

        let isLeftPress = dPadKeyPressed == .dPadLeft
        let isRightPress = dPadKeyPressed == .dPadRight

        // Increase the rewind speed if the player is already in rewind mode and
        // the player receives a D-pad left key press or long press.
        if isPlayerInRewindMode && isLeftPress {
            handleTrickPlayIncreaseSpeed(forSupportedRates: rewindSupportedRates)

            // Decrease the rewind speed if the player is already in rewind mode
            // and the player receives a D-pad right key press or long press.
        } else if isPlayerInRewindMode && isRightPress {
            handleTrickPlayDecreaseSpeed(forSupportedRates: rewindSupportedRates)

            // Increase the fast-forward speed if the player is already in
            // fast-forward mode and the player receives a D-pad right key press
            // or long press.
        } else if isPlayerInFastForwardMode && isRightPress {
            handleTrickPlayIncreaseSpeed(forSupportedRates: fastForwardSupportedRates)

            // Decrease the fast-forward speed if the player is already in
            // fast-forward mode and the player receives a D-pad right key press
            // or long press.
        } else if isPlayerInFastForwardMode && isLeftPress {
            handleTrickPlayDecreaseSpeed(forSupportedRates: fastForwardSupportedRates)
        }
    }

    /// Handles an increase of speed when the player is in trick play mode (fast forward or rewind).
    ///
    /// - Parameter supportedRates: The list of supported rates for the current trick play mode.
    private func handleTrickPlayIncreaseSpeed(forSupportedRates supportedRates: [Float]) {
        let currentRate = player.rate

        // Only increase the trick play speed if there's a next available rate
        // in the supportedRates list.
        guard let currentRateIdx = supportedRates.firstIndex(of: currentRate), (currentRateIdx + 1) < supportedRates.count else { return }

        // Update the player with the next available rate.
        let nextRateIdx = currentRateIdx + 1
        let nextRate = supportedRates[nextRateIdx]
        updatePlaybackRate(to: nextRate)
    }

    /// Handles a decrease of speed when the player is in trick play mode (fast forward or rewind).
    ///
    /// - Parameter supportedRates: The list of supported rates for the current trick play mode.
    private func handleTrickPlayDecreaseSpeed(forSupportedRates supportedRates: [Float]) {
        let currentRate = player.rate

        // Only decrease the trick play speed if there's a previous available
        // rate in the `supportedRates` list.
        guard let currentRateIdx = supportedRates.firstIndex(of: currentRate), (currentRateIdx - 1) >= 0 else { return }

        // Update the player with the previous rate.
        let previousRateIdx = currentRateIdx - 1
        let previousRate = supportedRates[previousRateIdx]
        updatePlaybackRate(to: previousRate)
    }

    // MARK: Playback controls

    /// Triggers play action.
    private func play() {
        switch playerState {

        case .playing:
            break

        case .stopped, .paused, .fastForwarding, .rewinding:
            player.play()
        }
    }

    /// Triggers pause action.
    private func pause() {
        switch playerState {

        case .stopped, .paused:
            break

        case .fastForwarding, .rewinding:
            // The dedicated pause button triggers a play action if the player
            // is in fast forward or rewind mode in the system player
            // (`AVPlayerViewController`).
            play()

        case .playing:
            player.pause()
        }
    }

    /// Toggles the custom player mode between play and pause.
    private func togglePlayPause() {
        switch playerState {

        case .playing:
            pause()

        case .stopped, .paused, .fastForwarding, .rewinding:
            play()
        }
    }

    /// Triggers stop action.
    private func stop() {
        // The dedicated stop button works the same way as the pause button in
        // the system player (`AVPlayerViewController`).
        pause()
    }

    // MARK: Navigating between tracks

   /// Triggers next track action.
    private func nextTrack() {
        // Play the first item if there's no item, or only one item, in the
        // player.
        if player.items().isEmpty || player.items().count == 1 {
            playItem(atIndex: 0)
        } else {
            player.advanceToNextItem()
        }
    }

    /// Triggers previous track action.
    private func previousTrack() {
        let channels = TVSchedule.shared.channels
        let currentItems = player.items()

        var previousIndex = channels.count - currentItems.count - 1
        // If out of bounds, play the last channel.
        if previousIndex < 0 {
            previousIndex = channels.count - 1
        }

        playItem(atIndex: previousIndex)
    }

    /// Plays the item at the specified index.
    ///
    /// - Parameter index: The index of the item to play.
    private func playItem(atIndex index: Int) {
        player.removeAllItems()

        for playerItem in TVSchedule.shared.playerItems[index...] {
            if player.canInsert(playerItem, after: nil) {
                player.insert(playerItem, after: nil)
            }
        }
    }

    // MARK: Navigating track content

    /// Updates the playback rate with the new value specified.
    ///
    /// - Parameter newRate: The new rate value.
    private func updatePlaybackRate(to newRate: Float) {
        player.rate = newRate
    }

    /// Updates the internal state of the custom player based on the player rate.
    private func updatePlayerState() {
        let currentRate = player.rate

        if currentRate == defaultPlaybackRate {
            playerState = .playing

        } else if currentRate == 0.0 {
            playerState = .paused

        } else if currentRate < 0 {
            playerState = .rewinding

        } else if currentRate > defaultPlaybackRate {
            playerState = .fastForwarding
        }

        // Reports player state update when the player state changes.
        reportPlayerStateUpdate()
    }

    /// Performs a seek action to the specified time.
    ///
    /// - Parameter time: The`CMTime` value to seek.
    private func seek(to time: CMTime) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            if finished {
                self.handlePlaybackChange()
            }
        }
    }

    /// Performs a seek action to the specified position.
    ///
    /// - Parameter position: The `TimeInterval` value to seek.
    private func seek(to position: TimeInterval) {
        seek(to: CMTime(seconds: position, preferredTimescale: 1))
    }

    /// Performs a seek backward action by the specified interval.
    ///
    /// - Parameter interval: The `TimeInterval` to perform the skip backward action.
    private func skipBackward(by interval: TimeInterval) {
        seek(to: player.currentTime() - CMTime(seconds: interval, preferredTimescale: 1))
    }

    /// Performs a seek forward action by the specified interval.
    ///
    /// - Parameter interval: The `TimeInterval` to perform the skip forward action.
    private func skipForward(by interval: TimeInterval) {
        seek(to: player.currentTime() + CMTime(seconds: interval, preferredTimescale: 1))
    }

    // MARK: Remote command center

    // Default rewind rates are 1x, 2x, 3x, and 4x.
    private let rewindSupportedRates: [Float] = [-8.0, -24.0, -48.0, -96.0]
    
    // Default fast-forward rates are 1x, 2x, 3x, and 4x.
    private let fastForwardSupportedRates: [Float] = [8.0, 24.0, 48.0, 96.0]

    // Default rate for playing.
    private let defaultPlaybackRate: Float = 1.0
    
    // Default rate for seeking.
    private let seekingRate: Float = 24.0
    
    // Default skip interval.
    private let skipInterval = 10.0

    /// The list of `RemoteCommand` objects that the player supports.
    private var supportedRemoteCommands: [RemoteCommand] {
        // In this sample project, the custom player supports all
        // available remote commands.
        RemoteCommand.allCases
    }

    /// Sets up the supported remote commands.
    private func setupSupportedRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Add support for every remote command the app supports. Each
        // `AVPlayerItem` may support different remote commands.
        for supportedCommand in supportedRemoteCommands {
            switch supportedCommand {
                // Define the rates and intervals for the commands that require them.
            case .changePlaybackRate:
                let allSupportedRates = rewindSupportedRates + fastForwardSupportedRates
                commandCenter
                    .changePlaybackRateCommand
                    .supportedPlaybackRates = allSupportedRates.map {
                        $0 as NSNumber
                    }

            case .skipBackward:
                commandCenter
                    .skipBackwardCommand
                    .preferredIntervals = [skipInterval as NSNumber]

            case .skipForward:
                commandCenter
                    .skipForwardCommand
                    .preferredIntervals = [skipInterval as NSNumber]

            default:
                break
            }

            // Remove each target before you add a new one.
            supportedCommand.mediaRemoteCommand.removeTarget(nil)
            supportedCommand.mediaRemoteCommand.addTarget {
                self.handle(command: supportedCommand, withCommandEvent: $0)
            }
        }
    }

    /// Tears down the remote commands that the player supports.
    private func tearDownSupportedRemoteCommands() {
        supportedRemoteCommands.forEach { $0.mediaRemoteCommand.removeTarget(nil) }
    }

    /// Handles a command that's previously registered with the remote command center, when the player
    /// receives it.
    ///
    /// - Parameter command: The `RemoteCommand` triggered.
    /// - Parameter commandEvent: The `MPRemoteCommandEvent` received.
    private func handle(command: RemoteCommand, withCommandEvent commandEvent: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus {
        var additionalInfo: String?
        switch command {
        // Playback commands.

            // Also handle play and pause in `setupGestureRecognizers()` in
            // `CustomPlayerViewController`.
        case .play:
            play()
        case .pause:
            pause()
        case .togglePlayPause:
            togglePlayPause()
        case .stop:
            stop()

        // Navigate between track commands.
        case .nextTrack:
            nextTrack()
        case .previousTrack:
            previousTrack()
        case .changeRepeatMode, .changeShuffleMode:
            // Implement if applicable to your app.
            print("Navigating between tracks commands")

        // Navigating track content commands.
        case .changePlaybackRate:
            guard let event = commandEvent as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            updatePlaybackRate(to: event.playbackRate)

        case .seekBackward:
            guard let event = commandEvent as? MPSeekCommandEvent else { return .commandFailed }
            let newRate: Float = (event.type == .beginSeeking) ? seekingRate : defaultPlaybackRate
            updatePlaybackRate(to: newRate)

        case .seekForward:
            guard let event = commandEvent as? MPSeekCommandEvent else { return .commandFailed }
            let newRate: Float = (event.type == .beginSeeking) ? seekingRate : defaultPlaybackRate
            updatePlaybackRate(to: newRate)

        case .skipBackward:
            let skipAllowed = playerState == .playing || playerState == .paused
            guard skipAllowed, let event = commandEvent as? MPSkipIntervalCommandEvent else { return .commandFailed }
            additionalInfo = String(event.interval)
            skipBackward(by: event.interval)

        case .skipForward:
            let skipAllowed = playerState == .playing || playerState == .paused
            guard skipAllowed, let event = commandEvent as? MPSkipIntervalCommandEvent else { return .commandFailed }
            additionalInfo = String(event.interval)
            skipForward(by: event.interval)

        case .changePlaybackPosition:
            guard let event = commandEvent as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            seek(to: event.positionTime)

        // Rating media items.
        case .rating, .like, .dislike:
            // Implement if applicable to your app.
            print("Rating media items commands")

        // Bookmarking media items.
        case .bookmark:
            // Implement if applicable to your app.
            print("Bookmarking media items")

        // Enabling language option.
        case .enableLanguageOption, .disableLanguageOption:
            // Implement if applicable to your app.
            print("Language option commands")
        }

        if let remoteEventForFeedback = remoteEventToReport(forRemoteCommandReceived: command) {
            reportRemoteEventReceived(remoteEventForFeedback, withAdditionalInfo: additionalInfo ?? "")
        }
        return .success
    }

    /// Gets the `RemoteEvent` for the respective `RemoteCommand` if it has a remote event to report.
    ///
    /// - Parameter remoteCommand: The `RemoteCommand` received.
    private func remoteEventToReport(forRemoteCommandReceived remoteCommand: RemoteCommand) -> RemoteEvent? {
        switch remoteCommand {
        case .skipForward:
            return RemoteEvent.skipForward

        case .skipBackward:
            return RemoteEvent.skipBackward

        case .nextTrack:
            return RemoteEvent.nextTrack

        case .previousTrack:
            return RemoteEvent.previousTrack

        default:
            // No remote event to report because the player state updates handle
            // all other commands.
            return nil
        }

    }

    // MARK: Player reporting feedback

    /// Reports remote events to the `CustomPlayerReporting` delegate with any specified
    /// additional information.
    ///
    /// - Parameter remoteEvent: The `RemoteEvent` to report.
    /// - Parameter additionalInfo: Any additional information relevant to the remote event
    /// received by the delegate.
    private func reportRemoteEventReceived(_ remoteEvent: RemoteEvent, withAdditionalInfo additionalInfo: String = "") {
        var feedbackText: String?
        switch remoteEvent {

        case .channelUp, .channelDown:
            feedbackText = String(format: "%@: %@", remoteEvent.rawValue, additionalInfo)

        case .skipForward, .skipBackward:
            feedbackText = String(format: "%@ %@", remoteEvent.rawValue, additionalInfo)

            // The following commands have the same feedback text output format:
            // a textual representation of the received remote event.
        case .nextTrack, .previousTrack, .dPadUp, .dPadDown, .swipeUp, .swipeDown, .swipeLeft, .swipeRight:
            feedbackText = remoteEvent.rawValue

        default:
            // The player handles all other remote events upon state changes.
            break
        }

        guard let feedbackText = feedbackText else { return }
        delegate?.reportFeedback(feedbackText, withFeedbackType: .shortLived)
    }

    /// Reports an update in the player state by notifying the `CustomPlayerReporting` delegate.
    private func reportPlayerStateUpdate() {
        var feedbackText = playerState.associatedRemoteEvent.rawValue

        let isTrickPlayMode = playerState == .fastForwarding || playerState == .rewinding
        let feedbackType: CustomPlayerFeedbackType = isTrickPlayMode ? .lasting : .shortLived

        // Only presents the speed indicator as part of the feedback on screen
        // if greater than 1 (2x, 3x, or 4x).
        if isTrickPlayMode, let speed = trickPlaySpeed(), speed > 1 {
            feedbackText += " \(speed)x"
        }

        delegate?.reportFeedback(feedbackText, withFeedbackType: feedbackType)
    }

    /// Gets the trick play mode speed based on the current rate of the custom player.
    ///
    /// If the player isn't currently in trick play mode (fast forward or rewind), this method returns `nil`.
    private func trickPlaySpeed() -> Int? {
        guard playerState == .fastForwarding || playerState == .rewinding else { return nil }

        let playerRate = player.rate
        var speedIndicator: Int? = nil

        if let rateIdx = fastForwardSupportedRates.firstIndex(of: playerRate) ?? rewindSupportedRates.firstIndex(of: playerRate) {
            speedIndicator = rateIdx + 1 // Accounts for the 0-index.
        }

        return speedIndicator
    }
}
