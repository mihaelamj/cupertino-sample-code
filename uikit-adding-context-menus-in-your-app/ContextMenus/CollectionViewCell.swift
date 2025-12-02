/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom collection view cell class for displaying numbered images.
*/

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "reuseIdentifier"

    @IBOutlet weak var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        let selectedBackgroundView = UIView(frame: bounds)
        selectedBackgroundView.backgroundColor = UIColor.lightGray
        self.selectedBackgroundView = selectedBackgroundView
    }

}
