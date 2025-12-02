/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom cell view cell that has a red background by default, and a blue background when selected.
*/

import UIKit

/// - Tag: custom-collection-view-cell
class CustomCollectionViewCell: UICollectionViewCell {
    
    static public let reuseID = "CustomCollectionViewCell"
    @IBOutlet var iconView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let redView = UIView(frame: bounds)
        redView.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
        self.backgroundView = redView

        let blueView = UIView(frame: bounds)
        blueView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 1, alpha: 1)
        self.selectedBackgroundView = blueView
    }
    
    func showIcon() {
        iconView.alpha = 1.0
    }
    
    func hideIcon() {
        iconView.alpha = 0.0
    }
}
