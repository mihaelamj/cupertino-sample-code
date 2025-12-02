/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller used for displaying a custom context menu for WKWebView.
*/

import UIKit

class ControlPreviewViewController: UIViewController {

    var image: UIImage!
    
    @IBOutlet var label: UILabel!
    @IBOutlet var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = title
        imageView.image = image
    }
    
}
