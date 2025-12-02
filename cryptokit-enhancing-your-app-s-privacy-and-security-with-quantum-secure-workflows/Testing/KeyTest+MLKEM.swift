/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Support for testing ML-KEM keys.
*/

import Foundation
import CryptoKit

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, *)
extension KeyTest {
    /// Tests the ML-KEM key of the given type.
    internal func testMLKEM(type: MLKEMType, useSecureEnclave: Bool) throws -> (TestStatus, String) {
        switch type {
        case .MLKEM768:
            return useSecureEnclave ? try check(try SecureEnclave.MLKEM768.PrivateKey()) : try check(try MLKEM768.PrivateKey())
        case .MLKEM1024:
            return useSecureEnclave ? try check(try SecureEnclave.MLKEM1024.PrivateKey()) : try check(try MLKEM1024.PrivateKey())
        }
    }

    private func check<K: KEMPrivateKey & GenericPasswordConvertible>(_ key: K) throws -> (TestStatus, String) {
        var description = key.description

        // Test that the key is the same after storing it and loading it from Keychain.
        let keychainKey = try GenericPasswordStore().roundTrip(key)
        if key.secKeyRepresentation != keychainKey.secKeyRepresentation {
            return (.fail, description + "\n❌ Keychain private key mismatch")
        }
        description.append("\n✅ Keychain private key match")

        // Perform a round-trip encapsulation/decapsulation.
        let encapsulation = try key.publicKey.encapsulate()
        description.append("\n\nEncapsulation contains \(encapsulation.encapsulated.count) bytes.")
        description.append("\nEncapsulation: " + encapsulation.encapsulated.subdata(in: 0..<32).base64EncodedString() + "...")
        let sharedSecret = try key.decapsulate(encapsulation.encapsulated)
        description.append("\nShared secret contains \(sharedSecret.bitCount / 8) bytes.")

        // Check that the shared secrets match.
        if encapsulation.sharedSecret != sharedSecret {
            return (.fail, description + "\n❌ Shared secret mismatch")
        }
        description.append("\n✅ Shared secret match")

        return (.pass, description)
    }
}
