/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller the sample uses for displaying a custom context menu.
*/

import UIKit

class PreviewViewController: UIViewController {
    
    var imageName: String!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var labelView: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        labelView.text = imageName
        imageView.image = UIImage(named: imageName)!
    }
    
}
