/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The `UICollectionViewCell` used to represent data in the collection view.
*/

import UIKit

final class Cell: UICollectionViewCell {
    // MARK: Properties

    static let reuseIdentifier = "Cell"

    /// The `UUID` for the data this cell is presenting.
    var representedIdentifier: UUID?

    // MARK: UICollectionViewCell

    override func awakeFromNib() {
        super.awakeFromNib()

        layer.borderWidth = 1.0
        layer.borderColor = UIColor.red.cgColor
    }

    // MARK: Convenience

    /**
     Configures the cell for display based on the model.
     
     - Parameters:
         - data: An optional `DisplayData` object to display.
     
     - Tag: Cell_Config
    */
    func configure(with data: DisplayData?) {
        backgroundColor = data?.color
    }
}
