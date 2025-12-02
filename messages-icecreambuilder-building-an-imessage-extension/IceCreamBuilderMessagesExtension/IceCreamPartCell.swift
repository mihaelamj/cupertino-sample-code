/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A `UICollectionViewCell` subclass used to display an ice cream part in the `BuildIceCreamViewController`.
*/

import UIKit

class IceCreamPartCell: UICollectionViewCell {
    
    static let reuseIdentifier = "IceCreamPartCell"
    
    @IBOutlet weak var imageView: UIImageView!

}
