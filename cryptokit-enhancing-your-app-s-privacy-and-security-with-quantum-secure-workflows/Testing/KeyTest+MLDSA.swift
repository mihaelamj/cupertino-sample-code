/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Support for testing ML-DSA keys.
*/

import Foundation
import CryptoKit

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, *)
extension KeyTest {
    /// Tests the ML-DSA key of the given type.
    internal func testMLDSA(type: MLDSAType) throws -> (TestStatus, String) {
        switch type {
        case .MLDSA65:
            return useSecureEnclave ? try check(try SecureEnclave.MLDSA65.PrivateKey()) : try check(try MLDSA65.PrivateKey())
        case .MLDSA87:
            return useSecureEnclave ? try check(try SecureEnclave.MLDSA87.PrivateKey()) : try check(try MLDSA87.PrivateKey())
        }
    }

    /// Note: This function can't be generic over all MLDSA keys because there isn't an MLDSA protocol to implement for them.
    private func check(_ key: MLDSA65.PrivateKey) throws -> (TestStatus, String) {
        var description = key.description

        // Test that the key is the same after storing it and loading it from Keychain.
        let keychainKey = try GenericPasswordStore().roundTrip(key)
        if key.secKeyRepresentation != keychainKey.secKeyRepresentation {
            return (.fail, description + "\n❌ Keychain private key mismatch")
        }
        description.append("\n✅ Keychain private key match")
        if key.publicKey.rawRepresentation != keychainKey.publicKey.rawRepresentation {
            return (.fail, description + "\n Keychain public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Perform a round-trip signature generation/verification.
        let message = "TEST MESSAGE"
        description.append("\n\nMessage to sign: " + message)
        let signature = try key.signature(for: Data(message.utf8))
        description.append("\nSignature contains \(signature.count) bytes")
        description.append("\nSignature: " + signature.subdata(in: 0..<32).base64EncodedString() + "...")
        if !key.publicKey.isValidSignature(signature: signature, for: Data(message.utf8)) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        // Perform a round-trip signature generation/verification with context.
        description.append("\n\nMessage to sign: " + message)
        let context = "TEST CONTEXT"
        description.append("\nContext: " + context)
        let signatureWithContext = try key.signature(for: Data(message.utf8), context: Data(context.utf8))
        description.append("\nSignature contains \(signatureWithContext.count) bytes")
        description.append("\nSignature: " + signatureWithContext.subdata(in: 0..<32).base64EncodedString() + "...")
        if !key.publicKey.isValidSignature(signature: signatureWithContext, for: Data(message.utf8), context: Data(context.utf8)) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        return (.pass, description)
    }

    private func check(_ key: MLDSA87.PrivateKey) throws -> (TestStatus, String) {
        var description = key.description

        // Test that the key is the same after storing it and loading it from Keychain.
        let keychainKey = try GenericPasswordStore().roundTrip(key)
        if key.secKeyRepresentation != keychainKey.secKeyRepresentation {
            return (.fail, description + "\n❌ Keychain private key mismatch")
        }
        description.append("\n✅ Keychain private key match")
        if key.publicKey.rawRepresentation != keychainKey.publicKey.rawRepresentation {
            return (.fail, description + "\n Keychain public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Perform a round-trip signature generation/verification.
        let message = "TEST MESSAGE"
        description.append("\n\nMessage to sign: " + message)
        let signature = try key.signature(for: Data(message.utf8))
        description.append("\nSignature contains \(signature.count) bytes")
        description.append("\nSignature: " + signature.subdata(in: 0..<32).base64EncodedString() + "...")
        if !key.publicKey.isValidSignature(signature: signature, for: Data(message.utf8)) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        // Perform a round-trip signature generation/verification with context.
        description.append("\n\nMessage to sign: " + message)
        let context = "TEST CONTEXT"
        description.append("\nContext: " + context)
        let signatureWithContext = try key.signature(for: Data(message.utf8), context: Data(context.utf8))
        description.append("\nSignature contains \(signatureWithContext.count) bytes")
        description.append("\nSignature: " + signatureWithContext.subdata(in: 0..<32).base64EncodedString() + "...")
        if !key.publicKey.isValidSignature(signature: signatureWithContext, for: Data(message.utf8), context: Data(context.utf8)) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        return (.pass, description)
    }

    private func check(_ key: SecureEnclave.MLDSA65.PrivateKey) throws -> (TestStatus, String) {
        var description = key.description

        // Test that the key is the same after storing it and loading it from Keychain.
        let keychainKey = try GenericPasswordStore().roundTrip(key)
        if key.secKeyRepresentation != keychainKey.secKeyRepresentation {
            return (.fail, description + "\n❌ Keychain private key mismatch")
        }
        description.append("\n✅ Keychain private key match")
        if key.publicKey.rawRepresentation != keychainKey.publicKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Perform a round-trip signature generation/verification.
        let message = "TEST MESSAGE"
        description.append("\n\nMessage to sign: " + message)
        let signature = try key.signature(for: Data(message.utf8))
        description.append("\nSignature contains \(signature.count) bytes")
        description.append("\nSignature: " + signature.subdata(in: 0..<32).base64EncodedString() + "...")
        if !key.publicKey.isValidSignature(signature: signature, for: Data(message.utf8)) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        // Perform a round-trip signature generation/verification with context.
        description.append("\n\nMessage to sign: " + message)
        let context = "TEST CONTEXT"
        description.append("\nContext: " + context)
        let signatureWithContext = try key.signature(for: Data(message.utf8), context: Data(context.utf8))
        description.append("\nSignature contains \(signatureWithContext.count) bytes")
        description.append("\nSignature: " + signatureWithContext.subdata(in: 0..<32).base64EncodedString() + "...")
        if !key.publicKey.isValidSignature(signature: signatureWithContext, for: Data(message.utf8), context: Data(context.utf8)) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        return (.pass, description)
    }

    private func check(_ key: SecureEnclave.MLDSA87.PrivateKey) throws -> (TestStatus, String) {
        var description = key.description

        // Test that the key is the same after storing it and loading it from Keychain.
        let keychainKey = try GenericPasswordStore().roundTrip(key)
        if key.secKeyRepresentation != keychainKey.secKeyRepresentation {
            return (.fail, description + "\n❌ Keychain private key mismatch")
        }
        description.append("\n✅ Keychain private key match")
        if key.publicKey.rawRepresentation != keychainKey.publicKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Perform a round-trip signature generation/verification.
        let message = "TEST MESSAGE"
        description.append("\n\nMessage to sign: " + message)
        let signature = try key.signature(for: Data(message.utf8))
        description.append("\nSignature contains \(signature.count) bytes")
        description.append("\nSignature: " + signature.subdata(in: 0..<32).base64EncodedString() + "...")
        if !key.publicKey.isValidSignature(signature: signature, for: Data(message.utf8)) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        // Perform a round-trip signature generation/verification with context.
        description.append("\n\nMessage to sign: " + message)
        let context = "TEST CONTEXT"
        description.append("\nContext: " + context)
        let signatureWithContext = try key.signature(for: Data(message.utf8), context: Data(context.utf8))
        description.append("\nSignature contains \(signatureWithContext.count) bytes")
        description.append("\nSignature: " + signatureWithContext.subdata(in: 0..<32).base64EncodedString() + "...")
        if !key.publicKey.isValidSignature(signature: signatureWithContext, for: Data(message.utf8), context: Data(context.utf8)) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        return (.pass, description)
    }
}
