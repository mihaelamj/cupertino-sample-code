/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A static table view controller which allows a `Contact` object to be edited.
*/

import UIKit

class ContactDetailViewController: UITableViewController {

    var contact: Contact?

    @IBOutlet var nameTextField: UITextField!
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var favoriteSwitch: UISwitch!

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let contact = contact else { preconditionFailure("Expected a Contact") }

        nameTextField.text = contact.name
        emailTextField.text = contact.email
        favoriteSwitch.isOn = contact.favorite
    }

    // MARK: - Actions
    
    @IBAction func toggleFavorite(sender: UISwitch) {
        contact?.favorite = sender.isOn
        
        // Update the model with the change.
        ContactsData.shared.updateContact(contact!)
    }

}

/// Implements very basic contact editing.

extension ContactDetailViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        if textField == nameTextField {
            contact?.name = textField.text ?? ""
        } else if textField == emailTextField {
            contact?.email = textField.text ?? ""
        }
        // Update the model with the change.
        ContactsData.shared.updateContact(contact!)
    }

}
