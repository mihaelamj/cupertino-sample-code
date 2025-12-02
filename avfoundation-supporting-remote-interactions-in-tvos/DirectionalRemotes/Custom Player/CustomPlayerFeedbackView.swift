/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The custom player feedback view that presents text in response to user actions.
*/

import UIKit

class CustomPlayerFeedbackView: UIView {

    private let feedbackDefaultFontSize: CGFloat = 57.0
    private let leadingSpacing: CGFloat = 84.0
    private let bottomSpacing: CGFloat = -170.0

    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [UIColor.black.withAlphaComponent(0.0).cgColor, UIColor.black.withAlphaComponent(0.8).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)

        self.layer.insertSublayer(gradientLayer, at: 0)

        return gradientLayer
    }()

    private lazy var feedbackLabel: UILabel = {
        let feedbackLabel = UILabel()
        feedbackLabel.translatesAutoresizingMaskIntoConstraints = false
        feedbackLabel.textColor = UIColor.white
        feedbackLabel.font = UIFont.boldSystemFont(ofSize: feedbackDefaultFontSize)
        return feedbackLabel
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
        // Invisible by default.
        self.alpha = 0.0

        self.addSubview(feedbackLabel)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            feedbackLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: leadingSpacing),
            feedbackLabel.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.90),
            feedbackLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: bottomSpacing)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Update the `gradientLayer`'s bounds.
        gradientLayer.frame = self.bounds
    }

    private func updateFeedback(_ feedbackText: String?) {
        feedbackLabel.text = feedbackText
    }

    // MARK: - Public methods

    /// Presents text on screen as feedback for a user action.
    ///
    /// - Parameter feedback: A `String` with the feedback text to present.
    /// - Parameter feedbackType: The `CustomPlayerFeedbackType` value indicating the
    /// type of feedback received.
    func presentFeedback(_ feedback: String, withFeedbackType feedbackType: CustomPlayerFeedbackType) {
        switch feedbackType {
        case .shortLived:
            presentShortLivedFeedback(feedback)
        case .lasting:
            presentLastingFeedback(feedback)
        }
    }

    // MARK: Present feedback methods

    private let animationDuration = 0.2

    /// Presents short-lived feedback, which stays on screen for 3 seconds.
    ///
    /// - Parameter feedback: The feedback to present on screen.
    private func presentShortLivedFeedback(_ feedback: String) {
        presentLastingFeedback(feedback)

        // Hide the short-lived feedback after 3 seconds.
        UIView.animate(withDuration: animationDuration, delay: 3.0, options: .curveEaseIn, animations: {
            self.alpha = 0.0
        }, completion: { finishedAnimation in
            if finishedAnimation {
                self.updateFeedback(nil)
            }
        })
    }

    /// Presents lasting feedback on screen, which stays on screen until another event occurs.
    ///
    /// - Parameter feedback: The feedback to present on screen.
    private func presentLastingFeedback(_ feedback: String) {
        // Remove animations in progress.
        if self.layer.animationKeys() != nil {
            self.layer.removeAllAnimations()
        }

        self.updateFeedback(feedback)
        UIView.animate(withDuration: animationDuration) {
            self.alpha = 1.0
        }
    }
}
