/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSTableViewCell for image inset.
*/

import UIKit

class TableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "reuseIdentifier"
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let insetFrame = imageView?.frame.insetBy(dx: 10.0, dy: 10.0)
        imageView!.frame = insetFrame!
    }
    
}
