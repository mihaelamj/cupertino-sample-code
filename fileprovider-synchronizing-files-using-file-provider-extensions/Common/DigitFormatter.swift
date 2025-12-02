/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A number formatter that considers only the digits 0-9 valid.
*/

import Foundation

class DigitFormatter: NumberFormatter, @unchecked Sendable {
    override func isPartialStringValid(_ partialString: String, newEditingString _: AutoreleasingUnsafeMutablePointer<NSString?>?,
                                       errorDescription _: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        guard !partialString.isEmpty else { return true }
        return UInt(partialString) != nil // Return true if only the characters 0-9 are present.
    }
}
