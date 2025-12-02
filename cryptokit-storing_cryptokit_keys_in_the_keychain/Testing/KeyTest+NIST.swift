/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Support for testing NIST keys.
*/

import Foundation
import CryptoKit

extension KeyTest {
    /// Tests the NIST key of the given size and purpose.
    internal func testNIST(size: NISTSize, purpose: Purpose) throws -> (TestStatus, String) {
        switch size {
        case .p256:
            switch purpose {
            case .signing:
                let key = P256.Signing.PrivateKey()
                return (try compare(key, SecKeyStore().roundTrip(key)), key.description)
            case .keyAgreement:
                let key = P256.KeyAgreement.PrivateKey()
                return (try compare(key, SecKeyStore().roundTrip(key)), key.description)
            }
        case .p384:
            switch purpose {
            case .signing:
                let key = P384.Signing.PrivateKey()
                return (try compare(key, SecKeyStore().roundTrip(key)), key.description)
            case .keyAgreement:
                let key = P384.KeyAgreement.PrivateKey()
                return (try compare(key, SecKeyStore().roundTrip(key)), key.description)
            }
        case .p521:
            switch purpose {
            case .signing:
                let key = P521.Signing.PrivateKey()
                return (try compare(key, SecKeyStore().roundTrip(key)), key.description)
            case .keyAgreement:
                let key = P384.KeyAgreement.PrivateKey()
                return (try compare(key, SecKeyStore().roundTrip(key)), key.description)
            }
        }
    }
}

// Test signing keys by signing data with one key and checking the signature with the other.
extension KeyTest {
    fileprivate var data: Data {
        return "Here's some data to use for testing".data(using: .utf8)!
    }
    
    fileprivate func compare(_ key1: P256.Signing.PrivateKey,
                             _ key2: P256.Signing.PrivateKey) throws -> TestStatus {
        return try key2.publicKey.isValidSignature(key1.signature(for: data), for: data) ? .pass : .fail
    }
    
    fileprivate func compare(_ key1: P384.Signing.PrivateKey,
                             _ key2: P384.Signing.PrivateKey) throws -> TestStatus {
        return try key2.publicKey.isValidSignature(key1.signature(for: data), for: data) ? .pass : .fail
    }
    
    fileprivate func compare(_ key1: P521.Signing.PrivateKey,
                             _ key2: P521.Signing.PrivateKey) throws -> TestStatus {
        return try key2.publicKey.isValidSignature(key1.signature(for: data), for: data) ? .pass : .fail
    }
}

// Test agreement keys by producing and comparing two shared secrets.
extension KeyTest {
    fileprivate func compare(_ key1: P256.KeyAgreement.PrivateKey,
                             _ key2: P256.KeyAgreement.PrivateKey) throws -> TestStatus {
        let sharedSecret1 = try key1.sharedSecretFromKeyAgreement(with: key2.publicKey)
        let sharedSecret2 = try key2.sharedSecretFromKeyAgreement(with: key1.publicKey)
        return sharedSecret1 == sharedSecret2 ? .pass : .fail
    }
    
    fileprivate func compare(_ key1: P384.KeyAgreement.PrivateKey,
                             _ key2: P384.KeyAgreement.PrivateKey) throws -> TestStatus {
        let sharedSecret1 = try key1.sharedSecretFromKeyAgreement(with: key2.publicKey)
        let sharedSecret2 = try key2.sharedSecretFromKeyAgreement(with: key1.publicKey)
        return sharedSecret1 == sharedSecret2 ? .pass : .fail
    }
    
    fileprivate func compare(_ key1: P521.KeyAgreement.PrivateKey,
                             _ key2: P521.KeyAgreement.PrivateKey) throws -> TestStatus {
        let sharedSecret1 = try key1.sharedSecretFromKeyAgreement(with: key2.publicKey)
        let sharedSecret2 = try key2.sharedSecretFromKeyAgreement(with: key1.publicKey)
        return sharedSecret1 == sharedSecret2 ? .pass : .fail
    }
}
