/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays visual feedback of user interactions with a remote.
*/
import MediaPlayer

class RemoteEventsViewController: UIViewController {

    private lazy var player = RemoteEventsPlayer()

    deinit {
        player.tearDown()
    }

    override func loadView() {
        let remoteEventsView = RemoteEventsView()
        self.view = remoteEventsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        player.delegate = self

        setupGuideButtonObserver()
        setupGestureRecognizers()
        setupAppLifecycleEventsHandlers()
    }

    // MARK: Guide button

    private func setupGuideButtonObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(guideButtonPressed),
                                               name: .guideButtonPressed,
                                               object: nil)
    }

    @objc
    private func guideButtonPressed() {
        reportRemoteEvent(.guide)
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

    @objc
    private func prepareForAppBackground() {
        player.prepareForAppBackground()
    }

    @objc
    private func prepareForAppForeground() {
        player.prepareForAppForeground()
    }

}

// MARK: RemoteEventsPlayerReporting

extension RemoteEventsViewController: RemoteEventsPlayerReporting {

    func playerReceived(remoteEvent: RemoteEvent) {
        reportRemoteEvent(remoteEvent)
    }
    
}

// MARK: Setup gesture recognizers

extension RemoteEventsViewController {
    private func setupGestureRecognizers() {
        // Handle a press on play/pause. You need to also implement the play/pause
        // functionality in the handle() method in `RemoteEventsPlayer`.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.playPause], forTarget: self, andAction: #selector(playPausePressed))
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.playPause], andAction: #selector(playPausePressed))

        // Handle a press or long press on select.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.select], forTarget: self, andAction: #selector(selectPressed))
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.select], andAction: #selector(selectPressed))

        // Handle a press or long press on channel up.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.pageUp], forTarget: self, andAction: #selector(channelUpPressed))
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.pageUp], andAction: #selector(channelUpPressed))
        // Handle a press or long press on channel down.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.pageDown], forTarget: self, andAction: #selector(channelDownPressed))
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.pageDown], andAction: #selector(channelDownPressed))

        // Handle a press or long press on the D-pad up key.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.upArrow], forTarget: self, andAction: #selector(dPadUpPressed))
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.upArrow], andAction: #selector(dPadUpPressed))
        // Handle a press or long press on the D-pad down key.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.downArrow], forTarget: self, andAction: #selector(dPadDownPressed))
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.downArrow], andAction: #selector(dPadDownPressed))
        // Handle a press or long press on the D-pad left key.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.leftArrow], forTarget: self, andAction: #selector(dPadLeftPressed))
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.leftArrow], andAction: #selector(dPadLeftPressed))
        // Handle a press or long press on the D-pad right key.
        addTapGestureRecognizer(toView: view, withAllowedPressTypes: [.rightArrow], forTarget: self, andAction: #selector(dPadRightPressed))
        addLongPressGestureRecognizer(toView: view, forTarget: self, withAllowedPressTypes: [.rightArrow], andAction: #selector(dPadRightPressed))

        // Handle swipe gestures.
        addSwipeGestureRecognizer(toView: view, withDirection: .left, forTarget: self, andAction: #selector(swipeLeftAction))
        addSwipeGestureRecognizer(toView: view, withDirection: .right, forTarget: self, andAction: #selector(swipeRightAction))
        addSwipeGestureRecognizer(toView: view, withDirection: .up, forTarget: self, andAction: #selector(swipeUpAction))
        addSwipeGestureRecognizer(toView: view, withDirection: .down, forTarget: self, andAction: #selector(swipeDownAction))
    }

    // MARK: Gesture recognizers action methods

    @objc
    private func playPausePressed(_ gesture: UIGestureRecognizer) {
        reportRemoteEvent(.playPause, withState: stateForLongPressGesture(gesture))
    }

    @objc
    private func selectPressed(_ gesture: UIGestureRecognizer) {
        reportRemoteEvent(.select, withState: stateForLongPressGesture(gesture))
    }

    @objc
    private func channelUpPressed(_ gesture: UIGestureRecognizer) {
        reportRemoteEvent(.channelUp, withState: stateForLongPressGesture(gesture))
    }

    @objc
    private func channelDownPressed(_ gesture: UIGestureRecognizer) {
        reportRemoteEvent(.channelDown, withState: stateForLongPressGesture(gesture))
    }

    @objc
    private func dPadUpPressed(_ gesture: UIGestureRecognizer) {
        reportRemoteEvent(.dPadUp, withState: stateForLongPressGesture(gesture))
    }

    @objc
    private func dPadDownPressed(_ gesture: UIGestureRecognizer) {
        reportRemoteEvent(.dPadDown, withState: stateForLongPressGesture(gesture))
    }

    @objc
    private func dPadLeftPressed(_ gesture: UIGestureRecognizer) {
        reportRemoteEvent(.dPadLeft, withState: stateForLongPressGesture(gesture))
    }

    @objc
    private func dPadRightPressed(_ gesture: UIGestureRecognizer) {
        reportRemoteEvent(.dPadRight, withState: stateForLongPressGesture(gesture))
    }

    @objc
    private func swipeUpAction() {
        reportRemoteEvent(.swipeUp)
    }

    @objc
    private func swipeDownAction() {
        reportRemoteEvent(.swipeDown)
    }

    @objc
    private func swipeLeftAction() {
        reportRemoteEvent(.swipeLeft)
    }

    @objc
    private func swipeRightAction() {
        reportRemoteEvent(.swipeRight)
    }

    /// Fetches the state of the long-press gesture. Returns `nil` if the gesture recognizer isn't
    /// a long-press gesture recognizer.
    ///
    /// - Parameter gesture: The gesture received.
    private func stateForLongPressGesture(_ gesture: UIGestureRecognizer) -> UIGestureRecognizer.State? {
        // Only pass on the state if it's a long press.
        var state: UIGestureRecognizer.State? = nil
        if gesture.isKind(of: UILongPressGestureRecognizer.self) {
            state = gesture.state
        }
        return state
    }

    /// Reports the remote event the controller's view receives.
    ///
    /// - Parameter remoteEvent: The received remote event.
    /// - Parameter state: The state of the received event, if any.
    private func reportRemoteEvent(_ remoteEvent: RemoteEvent,
                                   withState state: UIGestureRecognizer.State? = nil) {
        guard let remoteEventsView = self.view as? RemoteEventsView else { return }
        remoteEventsView.remoteEventReceived(remoteEvent, withState: state)
    }
}
