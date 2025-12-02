/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The `KeyboardSuggestionsViewController` contains text fields that are decorated with a `UITextContentType`.
 Each text field is annotated with a different level of granularity. Use this to verify that `NSUserActivity`
 donations in your app are valid and result in Keyboard Suggestions inside other apps. The keyboard
 should display the part of the location specified by the `UITextContentType` enum as the center recommendation.
*/

import UIKit

class KeyboardSuggestionsViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var streetAddressLine1TextField: UITextField!
    @IBOutlet weak var streetAddressLine2TextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var postalCodeTextField: UITextField!
    @IBOutlet weak var countryOrRegionTextField: UITextField!

    /// - Tag: keyboard_view_did_load
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // These properties can also be set on the field in Interface Builder.
        nameTextField.textContentType = .organizationName
        streetAddressLine1TextField.textContentType = .streetAddressLine1
        streetAddressLine2TextField.textContentType = .streetAddressLine2
        cityTextField.textContentType = .addressCity
        stateTextField.textContentType = .addressState
        postalCodeTextField.textContentType = .postalCode
        countryOrRegionTextField.textContentType = .countryName
    }
}

extension KeyboardSuggestionsViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
