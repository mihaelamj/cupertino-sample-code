/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The detail view controller in the Custom Back Button example.
*/

import UIKit

class CustomBackButtonDetailViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let backButtonBackgroundImage = UIImage(systemName: "list.bullet")
        let backButton = UIBarButtonItem(image: backButtonBackgroundImage,
                                         style: .plain,
                                         target: self,
                                         action: #selector(backButtonTapped(_:)))
        navigationItem.leftBarButtonItem = backButton
    }
    
    @objc
    func backButtonTapped(_ sender: AnyObject) {
        navigationController?.popViewController(animated: true)
    }
}
