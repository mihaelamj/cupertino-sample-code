/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection view cell subclass to show a thumbnail in the collection view.
*/

import UIKit

class AttachmentCVCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    weak var delegate: AttachmentInteractionDelegate?
    var attachment: Attachment!
    var indexPath: IndexPath!
    
    @IBAction func deleteAction(_ sender: UIButton) {
        delegate?.delete(attachment: attachment, at: indexPath)
    }
}
