/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that shows a full image.
*/

import UIKit

class ImageViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var fullImageView: UIImageView!
    
    var fullImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        fullImageView.translatesAutoresizingMaskIntoConstraints = false
        fullImageView.image = fullImage
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
}
