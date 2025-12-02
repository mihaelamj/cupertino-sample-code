/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Support for testing Secure Enclave keys.
*/

import Foundation
import CryptoKit

extension KeyTest {
    /// Tests the Secure Enclave key of the given purpose.
    internal func testSecureEnclave(purpose: Purpose) throws -> (TestStatus, String) {
        switch purpose {
        case .signing:
            let key = try SecureEnclave.P256.Signing.PrivateKey()
            return try (compare(key, GenericPasswordStore().roundTrip(key)), key.description)
        case .keyAgreement:
            let key = try SecureEnclave.P256.KeyAgreement.PrivateKey()
            return (try compare(key, GenericPasswordStore().roundTrip(key)), key.description)
        }
    }
    
    private var data: Data {
        return "Here's some data to use for testing".data(using: .utf8)!
    }
    
    /// Tests signing keys by signing data with one key and checking the signature with the other.
    private func compare(_ key1: SecureEnclave.P256.Signing.PrivateKey,
                         _ key2: SecureEnclave.P256.Signing.PrivateKey) throws -> TestStatus {
        return try key2.publicKey.isValidSignature(key1.signature(for: data), for: data) ? .pass : .fail
    }
    
    /// Tests agreement keys by producing and comparing two shared secrets.
    private func compare(_ key1: SecureEnclave.P256.KeyAgreement.PrivateKey,
                         _ key2: SecureEnclave.P256.KeyAgreement.PrivateKey) throws -> TestStatus {
        let sharedSecret1 = try key1.sharedSecretFromKeyAgreement(with: key2.publicKey)
        let sharedSecret2 = try key2.sharedSecretFromKeyAgreement(with: key1.publicKey)
        return sharedSecret1 == sharedSecret2 ? .pass : .fail
    }
}
