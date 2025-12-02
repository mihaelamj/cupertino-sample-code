/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A table view cell subclass for showing a post.
*/

import UIKit

class PostCell: TagCollectionCell {
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var hasAttachmentLabel: UILabel!
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        collectionView.backgroundColor = .clear
        super.setSelected(selected, animated: animated)
    }
}
