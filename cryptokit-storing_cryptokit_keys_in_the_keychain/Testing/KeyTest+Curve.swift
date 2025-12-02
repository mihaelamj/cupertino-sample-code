/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Support for testing Curve25219 keys.
*/

import Foundation
import CryptoKit

extension KeyTest {
    /// Tests the Curve25519 key of the given purpose.
    internal func testCurve(purpose: Purpose) throws -> (TestStatus, String) {
        switch purpose {
        case .signing:
            let key = Curve25519.Signing.PrivateKey()
            return (try compare(key, GenericPasswordStore().roundTrip(key)), key.description)
        case .keyAgreement:
            let key = Curve25519.KeyAgreement.PrivateKey()
            return (try compare(key, GenericPasswordStore().roundTrip(key)), key.description)
        }
    }
    
    private var data: Data {
        return "Here's some data to use for testing".data(using: .utf8)!
    }
    
    /// Tests signing keys by signing data with one key and checking the signature with the other.
    private func compare(_ key1: Curve25519.Signing.PrivateKey,
                         _ key2: Curve25519.Signing.PrivateKey) throws -> TestStatus {
        return try key2.publicKey.isValidSignature(key1.signature(for: data), for: data) ? .pass : .fail
    }
    
    /// Tests agreement keys by producing and comparing two shared secrets.
    private func compare(_ key1: Curve25519.KeyAgreement.PrivateKey,
                         _ key2: Curve25519.KeyAgreement.PrivateKey) throws -> TestStatus {
        let sharedSecret1 = try key1.sharedSecretFromKeyAgreement(with: key2.publicKey)
        let sharedSecret2 = try key2.sharedSecretFromKeyAgreement(with: key1.publicKey)
        return sharedSecret1 == sharedSecret2 ? .pass : .fail
    }
}
