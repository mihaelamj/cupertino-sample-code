/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example demonstrating setup of accessibility rotors to search for various text attributes on an text view.
*/

import Cocoa

class CustomRotorsTextView: NSTextView {
    
    weak var rotorDelegate: CustomRotorsTextViewDelegate?
    
    // MARK: Accessibility
    
    override func accessibilityCustomRotors() -> [NSAccessibilityCustomRotor] {
        return rotorDelegate?.createCustomRotors() ?? []
    }
}

// MARK: -

protocol CustomRotorsTextViewDelegate: AnyObject {
    func createCustomRotors() -> [NSAccessibilityCustomRotor]
}
