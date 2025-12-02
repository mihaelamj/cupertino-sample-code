/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension for the data.
*/

import Foundation

extension Data {
    
    func hexString() -> String {
        if isEmpty { return "" }
        return map { String(format: "%02x", $0) }.joined().uppercased()
    }
    
}
