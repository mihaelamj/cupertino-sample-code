/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that contains an image view to show a particular photo.
*/

import Foundation
import UIKit

class PhotoDetailViewController: UIViewController {
    
    var photo: Photo?

    @IBOutlet weak private var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let photo = photo {
            imageView.image = UIImage(named: photo.assetName)
            title = photo.title
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        view.window?.windowScene?.userActivity = photo?.detailUserActivity
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.window?.windowScene?.userActivity = nil
    }
    
}

extension PhotoDetailViewController {
    
    static func loadFromStoryboard() -> PhotoDetailViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        return storyboard.instantiateViewController(withIdentifier: "PhotoDetailViewController") as? PhotoDetailViewController
    }

}
