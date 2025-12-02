/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The UICollectionViewCell subclass that shows a thumbnail in UICollectionView.
*/

import UIKit

protocol ImagCVCellDelegate: AnyObject {
    func deleteCell(_ cell: UICollectionViewCell)
}

class ImageCVCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!

    weak var delegate: ImagCVCellDelegate?
    
    @IBAction func deleteAction(_ sender: UIButton) {
        delegate?.deleteCell(self)
    }
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .systemGray : .systemGray6
        }
    }
}
