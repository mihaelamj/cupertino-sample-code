/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A cell that displays a remote event.
*/

import UIKit

class RemoteEventsCell: UICollectionViewCell {

    static let identifier = "RemoteEventsCell"

    private let cellCornerRadius = 20.0
    private let textLabelHorizontalSpacing = 20.0

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.font = UIFont.preferredFont(forTextStyle: .body)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.textColor = UIColor.primaryLabelColor
        textLabel.textAlignment = .center
        return textLabel
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
        self.contentView.layer.cornerRadius = cellCornerRadius
        self.contentView.backgroundColor = UIColor.secondaryBackgroundColor

        self.contentView.addSubview(textLabel)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: textLabelHorizontalSpacing),
            textLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -textLabelHorizontalSpacing),
            textLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            textLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    // MARK: Public functions

    private let defaultAnimationDuration: CGFloat = 0.3

    /// Highlights the cell.
    func highlight() {
        highlight(withCompletion: nil)
    }

    /// Highlights the cell with a completion block.
    ///
    /// - Parameter completion: An optional completion block that's called when the highlight
    /// animation completes.
    private func highlight(withCompletion completion: ((Bool) -> Void)?) {
        // Check if there are animations in progress and remove them.
        if self.layer.animationKeys() != nil {
            self.layer.removeAllAnimations()
        }

        UIView.animate(withDuration: defaultAnimationDuration, animations: {
            self.contentView.backgroundColor = UIColor.highlightedBackgroundColor
            self.textLabel.textColor = UIColor.highlightedLabelColor
        }, completion: completion)
    }

    /// Removes the highlight of the cell.
    func removeHighlight() {
        UIView.animate(withDuration: defaultAnimationDuration) {
            self.contentView.backgroundColor = UIColor.secondaryBackgroundColor
            self.textLabel.textColor = UIColor.primaryLabelColor
        }
    }

    /// Blinks the cell by highlighting and removing the highlight.
    func blink() {
        highlight { [weak self] _ in
            self?.removeHighlight()
        }
    }
}
