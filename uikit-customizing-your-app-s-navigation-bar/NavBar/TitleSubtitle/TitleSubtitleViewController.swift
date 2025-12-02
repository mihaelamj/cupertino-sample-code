/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates configuring the navigation bar to show a title and subtitle.
*/

import UIKit

class TitleSubtitleViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Title"
        navigationItem.subtitle = "Subtitle"
    }
}
