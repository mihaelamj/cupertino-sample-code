/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom player view.
*/

import AVKit

class CustomPlayerView: UIView {

    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        guard let playerLayer = layer as? AVPlayerLayer else { fatalError("CustomPlayerView player layer must be AVPlayerLayer") }

        return playerLayer
    }

    var player: AVPlayer? {
        get {
            playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    private lazy var remoteFeedbackView: CustomPlayerFeedbackView = {
        let remoteFeedbackView = CustomPlayerFeedbackView()
        remoteFeedbackView.translatesAutoresizingMaskIntoConstraints = false
        return remoteFeedbackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        commonInit()
    }

    private func commonInit() {
        setupView()
        setupLayout()
    }

    private func setupView() {
        addSubview(remoteFeedbackView)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            remoteFeedbackView.widthAnchor.constraint(equalTo: self.widthAnchor),
            remoteFeedbackView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.4),
            remoteFeedbackView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    // MARK: Public methods

    /// Presents text on screen as feedback for a user action.
    ///
    /// - Parameter feedback: A `String` with the feedback text to present.
    /// - Parameter feedbackType: The `CustomPlayerFeedbackType` value that indicates the
    /// type of feedback.
    func presentFeedback(_ feedback: String, withFeedbackType feedbackType: CustomPlayerFeedbackType) {
        remoteFeedbackView.presentFeedback(feedback, withFeedbackType: feedbackType)
    }
}
