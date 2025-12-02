/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that plays video using a player with a custom UI.
*/

import TVUIKit

class CustomPlayerViewController: UIViewController {

    private lazy var customPlayer = CustomPlayer()

    deinit {
        customPlayer.tearDown()
    }

    override func loadView() {
        let customPlayerView = CustomPlayerView()
        customPlayerView.player = customPlayer.player

        self.view = customPlayerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        customPlayer.delegate = self

        setupGestureRecognizers()
        setupGuideButtonObserver()
        setupAppLifecycleEventsHandlers()
    }

    // MARK: Guide button

    private func setupGuideButtonObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(guideButtonPressed), name: .guideButtonPressed, object: nil)
    }

    @objc private func guideButtonPressed() {
        reportFeedback(RemoteEvent.guide.rawValue, withFeedbackType: .shortLived)
        // Add the logic here to present your guide view controller. Check
        // `GuideViewController` to make sure your page up and page down
        // functionality implements the desired behavior.
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
        customPlayer.prepareForAppBackground()
    }

    /// Prepares the view controller for an app foreground event.
    @objc private func prepareForAppForeground() {
        customPlayer.prepareForAppForeground()
    }

    // MARK: Gesture recognizers

    /// Sets up gesture recognizers for the various remote press types.
    private func setupGestureRecognizers() {
        // Handle a press on play/pause. You need to also implement the play/pause
        // functionality in the handle() method in CustomPlayer.
        addTapGestureRecognizer(toView: view,
                                withAllowedPressTypes: [.playPause],
                                forTarget: self,
                                andAction: #selector(playPausePressed))
        
        // Handle a press on select.
        addTapGestureRecognizer(toView: view,
                                withAllowedPressTypes: [.select],
                                forTarget: self,
                                andAction: #selector(selectPressed))

        // Handle presses on channel up and down.
        addTapGestureRecognizer(toView: view,
                                withAllowedPressTypes: [.pageUp],
                                forTarget: self,
                                andAction: #selector(channelUpPressed))
        addTapGestureRecognizer(toView: view,
                                withAllowedPressTypes: [.pageDown],
                                forTarget: self,
                                andAction: #selector(channelDownPressed))

        // Handle presses on the D-pad up, down, left, and right keys.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.upArrow], forTarget: self, andAction: #selector(dPadUpPressed))
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.downArrow], forTarget: self, andAction: #selector(dPadDownPressed))
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.leftArrow], forTarget: self, andAction: #selector(dPadLeftPressed))
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.rightArrow], forTarget: self, andAction: #selector(dPadRightPressed))

        // Handle long presses on the D-pad left and right keys.
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.leftArrow], andAction: #selector(dPadLeftLongPress))
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.rightArrow], andAction: #selector(dPadRightLongPress))

        // Handle swipe gestures.
        addSwipeGestureRecognizer(toView: view, withDirection: .left, forTarget: self, andAction: #selector(swipeLeftAction))
        addSwipeGestureRecognizer(toView: view, withDirection: .right, forTarget: self, andAction: #selector(swipeRightAction))
        addSwipeGestureRecognizer(toView: view, withDirection: .up, forTarget: self, andAction: #selector(swipeUpAction))
        addSwipeGestureRecognizer(toView: view, withDirection: .down, forTarget: self, andAction: #selector(swipeDownAction))
    }

    // MARK: Gesture recognizers action methods

    @objc private func playPausePressed() {
        customPlayer.remoteEventReceived(.playPause)
    }

    @objc private func selectPressed() {
        customPlayer.remoteEventReceived(.select)
    }

    @objc private func channelUpPressed() {
        customPlayer.remoteEventReceived(.channelUp)
    }

    @objc private func channelDownPressed() {
        customPlayer.remoteEventReceived(.channelDown)
    }

    // Handle swipe gestures.

    @objc private func swipeLeftAction() {
        customPlayer.remoteEventReceived(.swipeLeft)
    }

    @objc private func swipeRightAction() {
        customPlayer.remoteEventReceived(.swipeRight)
    }

    @objc private func swipeUpAction() {
        customPlayer.remoteEventReceived(.swipeUp)
    }

    @objc private func swipeDownAction() {
        customPlayer.remoteEventReceived(.swipeDown)
    }

    // Handle D-pad key presses.

    @objc private func dPadUpPressed() {
        customPlayer.remoteEventReceived(.dPadUp)
    }

    @objc private func dPadDownPressed() {
        customPlayer.remoteEventReceived(.dPadDown)
    }

    @objc private func dPadLeftPressed() {
        customPlayer.remoteEventReceived(.dPadLeft)
    }

    @objc private func dPadRightPressed() {
        customPlayer.remoteEventReceived(.dPadRight)
    }

    // Handle D-pad key long presses.

    @objc private func dPadLeftLongPress(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            customPlayer.handlePlayerBehaviorForDPadKeyPress(.dPadLeft, isLongPress: true)
        }
    }

    @objc private func dPadRightLongPress(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            customPlayer.handlePlayerBehaviorForDPadKeyPress(.dPadRight, isLongPress: true)
        }
    }
}

// MARK: CustomPlayerReporting protocol methods

extension CustomPlayerViewController: CustomPlayerReporting {

    func reportFeedback(_ feedback: String, withFeedbackType feedbackType: CustomPlayerFeedbackType) {
        guard let view = self.view as? CustomPlayerView else { return }

        view.presentFeedback(feedback, withFeedbackType: feedbackType)
    }
}
