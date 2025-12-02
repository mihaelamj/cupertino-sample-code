/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The cell to show a poster for the media.
*/

import UIKit
import TVUIKit

class PosterCollectionViewCell: UICollectionViewCell {

    var color: UIColor {
        didSet {
            posterView.color = color
        }
    }

    var symbol: String {
        didSet {
            posterView.symbol = symbol
        }
    }

    private let lockupView: TVCardView
    private let posterView: PosterView

    override init(frame: CGRect) {
        color = .white
        symbol = ""
        lockupView = TVCardView(frame: .zero)
        posterView = PosterView(frame: .zero)
        super.init(frame: frame)
        lockupView.contentView.addSubview(posterView)
        contentView.addSubview(lockupView)

        lockupView.translatesAutoresizingMaskIntoConstraints = false
        posterView.translatesAutoresizingMaskIntoConstraints = false

        // Make sure to set the correct content size, and only add constraints
        // to the `centerX` and `centerY` for `TVLockupView` and related classes
        // like `TVCardView`. This way you get the desired focused view effect.
        lockupView.contentSize = frame.size

        NSLayoutConstraint.activate([
            lockupView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            lockupView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            posterView.topAnchor.constraint(equalTo: lockupView.contentView.topAnchor),
            posterView.bottomAnchor.constraint(equalTo: lockupView.contentView.bottomAnchor),
            posterView.leadingAnchor.constraint(equalTo: lockupView.contentView.leadingAnchor),
            posterView.trailingAnchor.constraint(equalTo: lockupView.contentView.trailingAnchor)
            ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
