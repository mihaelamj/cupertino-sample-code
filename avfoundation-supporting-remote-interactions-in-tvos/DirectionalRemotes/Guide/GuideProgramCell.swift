/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A cell that displays a program in the guide.
*/

import UIKit
import CoreGraphics

class GuideProgramCell: UICollectionViewCell {

    static let identifier = "GuideProgramCell"
    static let width = 1600.0

    private let programCellCornerRadius: CGFloat = 24

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .left
        titleLabel.enablesMarqueeWhenAncestorFocused = true
        return titleLabel
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
        self.contentView.layer.cornerRadius = programCellCornerRadius
        self.contentView.addSubview(titleLabel)

        updateColors()
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    // MARK: Public methods

    func updateProgramTitle(_ programTitle: String) {
        titleLabel.text = programTitle
    }

    // MARK: UICollectionViewCell methods

    override func prepareForReuse() {
        super.prepareForReuse()

        self.isHighlighted = false
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)

        coordinator.addCoordinatedAnimations(self.updateColors)
    }

    override var isHighlighted: Bool {
        didSet {
            self.updateColors()
            self.setNeedsFocusUpdate()
        }
    }

    // MARK: Update cell colors

    /// Updates the colors in the cell based on its state.
    ///
    /// The background and text label colors are updated based on the cell state, if highlighted or focused.
    private func updateColors() {
        contentView.backgroundColor = cellBackgroundColor
        titleLabel.textColor = textColor
    }

    private var textColor: UIColor {
        (self.isHighlighted || self.isFocused) ? UIColor.highlightedLabelColor : UIColor.primaryLabelColor
    }

    private var cellBackgroundColor: UIColor {
        (self.isHighlighted || self.isFocused) ? UIColor.highlightedBackgroundColor : UIColor.secondaryBackgroundColor
    }
}
