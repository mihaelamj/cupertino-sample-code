/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Errors that the system generates as a result of attempting to store keys.
*/

import Foundation

/// An error to throw when something goes wrong.
struct KeyStoreError: Error, CustomStringConvertible {
    var message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var description: String {
        return message
    }
}

extension OSStatus {
    
    /// A human-readable message for the status.
    var message: String {
        return (SecCopyErrorMessageString(self, nil) as String?) ?? String(self)
    }
}
