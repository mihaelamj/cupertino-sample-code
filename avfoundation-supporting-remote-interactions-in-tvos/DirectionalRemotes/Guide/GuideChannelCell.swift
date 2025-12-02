/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A cell that displays a channel in the guide.
*/

import UIKit

class GuideChannelCell: UICollectionViewCell {

    static let identifier = "GuideChannelCell"
    static let width = 250.0

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        titleLabel.minimumScaleFactor = 0.75
        titleLabel.adjustsFontSizeToFitWidth = true

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
        self.contentView.addSubview(titleLabel)
        // The channel cell is initially not highlighted.
        isHighlighted = false
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: Public functions

    /// Updates the channel name in the cell.
    ///
    /// - Parameter channelName: The new channel name.
    func updateChannelName(_ channelName: String) {
        titleLabel.text = channelName
    }

    // MARK: UICollectionViewCell functions

    override var isHighlighted: Bool {
        didSet {
            titleLabel.textColor = isHighlighted ? UIColor.highlightedLabelColor : UIColor.secondaryLabelColor
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.isHighlighted = false
    }
}
