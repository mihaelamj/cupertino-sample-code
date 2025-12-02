/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom collection view cell that `CollectionViewController` displays.
*/

import UIKit

class CollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "reuseIdentifier"

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewOverlay: UIView!
    @IBOutlet weak var imageViewSelected: UIImageView!
    @IBOutlet weak var imageViewUnselected: UIImageView!
    
    private var showSelectionIcons = false

    override func awakeFromNib() {
        super.awakeFromNib()
        // Turn `imageViewSelected` into a circle to make its background
        // color act as a border around the checkmark symbol.
        imageViewSelected.layer.cornerRadius = imageViewSelected.bounds.width / 2
        imageViewUnselected.layer.cornerRadius = imageViewSelected.bounds.width / 2
    }
    
    func configureCell(with model: PhotoModel, showSelectionIcons: Bool) {
        self.showSelectionIcons = showSelectionIcons
        if let image = model.image {
            imageView.image = image
        }
    }
    
    override func layoutSubviews() {
        imageViewOverlay.alpha = isSelected ? 1.0 : 0.0
        imageViewSelected.alpha = (isSelected && showSelectionIcons) ? 1.0 : 0.0
        imageViewUnselected.alpha = showSelectionIcons ? 1.0 : 0.0
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        showSelectionIcons = false
    }
    
    override var isSelected: Bool {
        didSet { setNeedsLayout() }
    }
}
