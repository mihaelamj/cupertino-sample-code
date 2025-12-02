/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Primary or initial detail view controller for the split view.
*/

import UIKit

class InitialDetailViewController: UIViewController {

    @IBOutlet var detailLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            detailLabel.text = appName
        } else {
            if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
                detailLabel.text = appName
            }
        }
    }
    
}

