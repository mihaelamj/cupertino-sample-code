/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A `UICollectionViewCell` subclass used to display an `IceCream` in the `IceCreamsViewController`.
*/

import UIKit
import Messages

class IceCreamCell: UICollectionViewCell {
    
    static let reuseIdentifier = "IceCreamCell"
    
    var representedIceCream: IceCream?
    
    @IBOutlet weak var stickerView: MSStickerView!
    
}
