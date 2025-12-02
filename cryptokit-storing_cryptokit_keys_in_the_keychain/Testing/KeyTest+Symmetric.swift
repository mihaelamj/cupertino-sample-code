/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Support for testing symmetric keys.
*/

import Foundation
import CryptoKit

extension KeyTest {
    /// Tests the symmetric key of the given size.
    internal func testSymmetric(bits: SymmetricSize) throws -> (TestStatus, String) {
        switch bits {
        case .bits128:
            let key = SymmetricKey(size: .bits128)
            return (try compare(key, GenericPasswordStore().roundTrip(key)), key.description)
        case .bits192:
            let key = SymmetricKey(size: .bits192)
            return (try compare(key, GenericPasswordStore().roundTrip(key)), key.description)
        case .bits256:
            let key = SymmetricKey(size: .bits256)
            return (try compare(key, GenericPasswordStore().roundTrip(key)), key.description)
        }
    }
    
    /// Tests symmetric keys by comparing them directly.
    private func compare(_ key1: SymmetricKey,
                         _ key2: SymmetricKey) -> TestStatus {
        return key1.rawRepresentation == key2.rawRepresentation ? .pass : .fail
    }
}
