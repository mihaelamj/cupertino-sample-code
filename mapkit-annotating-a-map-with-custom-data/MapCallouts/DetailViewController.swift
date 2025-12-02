/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The detail view controller used for displaying the Golden Gate Bridge either in a popover for iPad,
 or in a modal view controller for iPhone.
*/

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let image = imageView.image {
            preferredContentSize = image.size
        }
    }
    
    @IBAction private func doneAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
