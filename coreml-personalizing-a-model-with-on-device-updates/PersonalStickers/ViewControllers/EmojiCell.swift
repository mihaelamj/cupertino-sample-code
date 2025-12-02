/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
UICollectionViewCell subclass that displays a single emoji.
*/

import UIKit

class EmojiCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    var emoji = "❓" { didSet { label.text = emoji } }
}
