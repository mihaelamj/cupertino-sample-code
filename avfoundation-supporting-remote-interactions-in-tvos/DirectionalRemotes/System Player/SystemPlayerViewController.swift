/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that plays video using the system player.
*/

import AVKit
import MediaPlayer
class SystemPlayerViewController: UIViewController {

    private var channelIdToPlay: Int?

    private var playerItemStatusObservation: NSKeyValueObservation?

    private lazy var playerViewController = AVPlayerViewController()
    private lazy var player = AVQueuePlayer(items: TVSchedule.shared.playerItems)

    /// Initializes the `NativePlayerViewController` with a specific channel ID to play.
    ///
    /// - Parameter channelIdToPlay: The channel ID to start playing.
    convenience init(channelIdToPlay: Int) {
        self.init(nibName: nil, bundle: nil)

        self.channelIdToPlay = channelIdToPlay
    }

    deinit {
        tearDown()
    }

    /// Prepares the view controller for dismissal.
    private func tearDown() {
        playerItemStatusObservation?.invalidate()
        playerItemStatusObservation = nil

        playerViewController.player = nil
        playerViewController.viewIfLoaded?.removeFromSuperview()
        playerViewController.willMove(toParent: nil)
        playerViewController.removeFromParent()

        player.pause()
        player.removeAllItems()
    }

    // MARK: UIViewController lifecycle methods

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        tearDownAdditionalRemoteCommands()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupAdditionalRemoteCommands()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupAVPlayerViewController()
        setupGestureRecognizers()
        setupAppLifecycleEventsHandlers()
    }

    override func viewWillLayoutSubviews() {
        playerViewController.view.frame = view.bounds

        super.viewWillLayoutSubviews()
    }

    // MARK: AVPlayerViewController setup

    /// Sets up the player view controller.
    private func setupAVPlayerViewController() {
        // Handle the case where it needs to play a specific channel.
        if let channelIdToPlay {
            playItem(atIndex: channelIdToPlay)
        }

        // Set up player view controller.
        playerViewController.view.frame = self.view.bounds
        addChild(playerViewController)
        playerViewController.didMove(toParent: self)
        view.addSubview(playerViewController.view)

        playerViewController.delegate = self

        // Set up the item status observation.
        playerItemStatusObservation = player.observe(\.currentItem?.status) { [weak self] _, _ in
            // Wait until the current item is ready to play before you set the
            // player on the player view controller and start to play it.
            guard let self = self,
                  self.player.currentItem?.status == .readyToPlay else { return }

            self.playerViewController.player = self.player
            self.player.play()

            // Set up the additional remote commands.
            self.setupAdditionalRemoteCommands()
        }
    }

    // MARK: App lifecycle events handlers

    private func setupAppLifecycleEventsHandlers() {
        // Observe when the app moved to the background.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(prepareForAppBackground),
                                               name: .applicationDidEnterBackgroundNotification,
                                               object: nil)

        // Observe when the app is about to come to the foreground.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(prepareForAppForeground),
                                               name: .applicationWillEnterForegroundNotification,
                                               object: nil)
    }

    /// Prepares the view controller for an app background event.
    @objc private func prepareForAppBackground() {
        tearDownAdditionalRemoteCommands()
    }

    /// Prepares the view controller for an app foreground event.
    @objc private func prepareForAppForeground() {
        setupAdditionalRemoteCommands()
    }

    // MARK: MPRemoteCommandCenter setup
    
    /// `AVPlayerViewController` doesn't internally respond to `previousTrackCommand` and
    /// `nextTrackCommand` commands. Therefore, set up handlers for those commands.
    private var additionalRemoteCommands: [RemoteCommand] {
        [.previousTrack, .nextTrack]
    }

    /// Sets up the targets and handlers for the additional supported remote commands that
    /// `AVPlayerViewController` doesn't internally handle.
    private func setupAdditionalRemoteCommands() {
        additionalRemoteCommands.forEach { [weak self] remoteCommand in
            guard let self = self else { return }
            // Remove each target before you add a new one.
            remoteCommand.mediaRemoteCommand.removeTarget(nil)
            remoteCommand.mediaRemoteCommand.addTarget { _ in
                self.handleCommand(remoteCommand)
            }
        }
    }

    /// Removes the targets and handlers for the additional supported remote commands that aren't
    /// internally handled by the `AVPlayerViewController`.
    private func tearDownAdditionalRemoteCommands() {
        additionalRemoteCommands.forEach { $0.mediaRemoteCommand.removeTarget(nil) }
    }

    /// Handles the `RemoteCommand` objects you registered with the remote command center.
    ///
    /// - Parameter command: The `RemoteCommand` object received.
    private func handleCommand(_ command: RemoteCommand) ->
    MPRemoteCommandHandlerStatus {
        switch command {
            // The previous track translates to channel down.
        case .previousTrack:
            channelDown()
            // The next track translates to channel up.
        case .nextTrack:
            channelUp()
        default:
            // AVPlayerViewController handles all other commands.
            return .commandFailed
        }
        return .success
    }

    // MARK: Gesture recognizers

    /// Sets up the required gesture recognizers for the system player.
    private func setupGestureRecognizers() {
        // Handle a channel up press.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.pageUp], forTarget: self, andAction: #selector(channelUp))

        // Handle a channel down press.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.pageDown], forTarget: self, andAction: #selector(channelDown))
    }

    /// Performs a channel up action by playing the next item in the player items list. If the currently
    /// playing channel is the last one in the list, a channel up press plays the first channel.
    @objc private func channelUp() {
        // If there's only one item left in the player items list, play the first
        // channel.
        if player.items().count == 1 {
            playItem(atIndex: 0)
        } else {
            player.advanceToNextItem()
        }
    }

    /// Performs a channel down action by playing the previous item in the player items list. If the
    /// currently playing channel is the first one in the list, a channel down press plays the last channel.
    @objc private func channelDown() {
        var previousChannelIndex = currentChannelIdx - 1
        // If out of bounds, play the last channel of the list.
        if previousChannelIndex < 0 {
            previousChannelIndex = TVSchedule.shared.channels.count - 1
        }

        playItem(atIndex: previousChannelIndex)
    }

    /// The index of the currently playing item.
    var currentChannelIdx: Int {
        let channelsCount = TVSchedule.shared.channels.count
        let currentItemsCount = player.items().count

        return channelsCount - currentItemsCount
    }

    /// Plays the item in the specified index.
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
}

extension SystemPlayerViewController: AVPlayerViewControllerDelegate {

    // Important: The following methods are only triggered when the currently
    // playing content is live. If content is streaming live, implement the
    // following delegate methods to react to channel switch swipe gestures.

    func playerViewController(_ playerViewController: AVPlayerViewController,
                              skipToPreviousChannel completion: @escaping (Bool) -> Void) {
        channelDown()
        completion(true)
    }

    func playerViewController(_ playerViewController: AVPlayerViewController,
                              skipToNextChannel completion: @escaping (Bool) -> Void) {
        channelUp()
        completion(true)
    }
}
