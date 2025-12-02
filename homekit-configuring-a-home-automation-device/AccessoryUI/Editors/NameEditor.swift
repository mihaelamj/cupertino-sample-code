/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Enables editing a name field.
*/

import UIKit
import HomeKit

class NameEditor: UITableViewController {

    @IBOutlet weak var nameField: UITextField!

    var service: HMService?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameField.text = service?.name
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let name = nameField.text,
            let service = service {

            HomeStore.shared.updateService(service, name: name)
        }
    }
}
