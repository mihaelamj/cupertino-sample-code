/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Support for testing hybrid signature keys.
*/

import Foundation
import CryptoKit

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, *)
extension KeyTest {
    /// Tests the hybrid signature key of the given type.
    internal func testHybridSig(type: HybridSigType) throws -> (TestStatus, String) {
        switch type {
        case .MLDSA65xP256:
            if useSecureEnclave {
                return try check(try SecureEnclave.MLDSA65.PrivateKey(), SecureEnclave.P256.Signing.PrivateKey())
            }
            return try check(try MLDSA65.PrivateKey(), P256.Signing.PrivateKey())
        case .MLDSA87xP384:
            return try check(try MLDSA87.PrivateKey(), P384.Signing.PrivateKey())
        }
    }

    /// Note: This function can't be generic over all MLDSA keys because there isn't an MLDSA protocol to implement for them.
    private func check(_ PQKey: MLDSA65.PrivateKey, _ ECKey: P256.Signing.PrivateKey) throws -> (TestStatus, String) {
        var description = "PQ " + PQKey.description
        description.append("\nEC " + ECKey.description)

        // Test that the PQ key is the same after storing it and loading it from Keychain.
        let keychainPQKey = try GenericPasswordStore().roundTrip(PQKey)
        if PQKey.secKeyRepresentation != keychainPQKey.secKeyRepresentation {
            return (.fail, description + "\n❌ Keychain PQ private key mismatch")
        }
        description.append("\n✅ Keychain PQ private key match")
        if PQKey.publicKey.rawRepresentation != keychainPQKey.publicKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain PQ public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Test that the EC key is the same after storing it and loading it from Keychain.
        let keychainECKey = try SecKeyStore().roundTrip(ECKey)
        if ECKey.rawRepresentation != keychainECKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain EC private key mismatch")
        }
        description.append("\n✅ Keychain EC private key match")
        if ECKey.publicKey.rawRepresentation != keychainECKey.publicKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain EC public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Generate a hybrid signature.
        let message = "TEST MESSAGE"
        description.append("\n\nMessage to sign: " + message)
        let PQSignature = try PQKey.signature(for: Data(message.utf8))
        let PQSignatureSize = PQSignature.count
        let ECSignature = try ECKey.signature(for: Data(message.utf8)).rawRepresentation
        let signature = PQSignature + ECSignature
        description.append("\nSignature contains \(signature.count) bytes")
        description.append("\nSignature: " + signature.subdata(in: 0..<32).base64EncodedString() + "...")

        // Verify the hybrid signature.
        let receivedPQSignature = signature.subdata(in: 0..<PQSignatureSize)
        let isValidPQSignature = PQKey.publicKey.isValidSignature(signature: receivedPQSignature, for: Data(message.utf8))
        let receivedECSignature = try P256.Signing.ECDSASignature(rawRepresentation: signature.subdata(in: PQSignatureSize..<signature.count))
        let isValidECSignature = ECKey.publicKey.isValidSignature(receivedECSignature, for: Data(message.utf8))
        if !(isValidPQSignature && isValidECSignature) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        return (.pass, description)
    }

    private func check(_ PQKey: MLDSA87.PrivateKey, _ ECKey: P384.Signing.PrivateKey) throws -> (TestStatus, String) {
        var description = "PQ " + PQKey.description
        description.append("\nEC " + ECKey.description)

        // Test that the PQ key is the same after storing it and loading it from Keychain.
        let keychainPQKey = try GenericPasswordStore().roundTrip(PQKey)
        if PQKey.secKeyRepresentation != keychainPQKey.secKeyRepresentation {
            return (.fail, description + "\n❌ Keychain PQ private key mismatch")
        }
        description.append("\n✅ Keychain PQ private key match")
        if PQKey.publicKey.rawRepresentation != keychainPQKey.publicKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain PQ public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Test that the EC key is the same after storing it and loading it from Keychain.
        let keychainECKey = try SecKeyStore().roundTrip(ECKey)
        if ECKey.rawRepresentation != keychainECKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain EC private key mismatch")
        }
        description.append("\n✅ Keychain EC private key match")
        if ECKey.publicKey.rawRepresentation != keychainECKey.publicKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain EC public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Generate a hybrid signature.
        let message = "TEST MESSAGE"
        description.append("\n\nMessage to sign: " + message)
        let PQSignature = try PQKey.signature(for: Data(message.utf8))
        let PQSignatureSize = PQSignature.count
        let ECSignature = try ECKey.signature(for: Data(message.utf8)).rawRepresentation
        let signature = PQSignature + ECSignature
        description.append("\nSignature contains \(signature.count) bytes")
        description.append("\nSignature: " + signature.subdata(in: 0..<32).base64EncodedString() + "...")

        // Verify the hybrid signature.
        let receivedPQSignature = signature.subdata(in: 0..<PQSignatureSize)
        let isValidPQSignature = PQKey.publicKey.isValidSignature(signature: receivedPQSignature, for: Data(message.utf8))
        let receivedECSignature = try P384.Signing.ECDSASignature(rawRepresentation: signature.subdata(in: PQSignatureSize..<signature.count))
        let isValidECSignature = ECKey.publicKey.isValidSignature(receivedECSignature, for: Data(message.utf8))
        if !(isValidPQSignature && isValidECSignature) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        return (.pass, description)
    }

    private func check(_ PQKey: SecureEnclave.MLDSA65.PrivateKey, _ ECKey: SecureEnclave.P256.Signing.PrivateKey) throws -> (TestStatus, String) {
        var description = "PQ " + PQKey.description
        description.append("\nEC " + ECKey.description)

        // Test that the PQ key is the same after storing it and loading it from Keychain.
        let keychainPQKey = try GenericPasswordStore().roundTrip(PQKey)
        if PQKey.secKeyRepresentation != keychainPQKey.secKeyRepresentation {
            return (.fail, description + "\n❌ Keychain PQ private key mismatch")
        }
        description.append("\n✅ Keychain PQ private key match")
        if PQKey.publicKey.rawRepresentation != keychainPQKey.publicKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain PQ public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Test that the EC key is the same after storing it and loading it from Keychain.
        let keychainECKey = try GenericPasswordStore().roundTrip(ECKey)
        if ECKey.secKeyRepresentation != keychainECKey.secKeyRepresentation {
            return (.fail, description + "\n❌ Keychain EC private key mismatch")
        }
        description.append("\n✅ Keychain EC private key match")
        if ECKey.publicKey.rawRepresentation != keychainECKey.publicKey.rawRepresentation {
            return (.fail, description + "\n❌ Keychain EC public key mismatch")
        }
        description.append("\n✅ Keychain public key match")

        // Generate a hybrid signature.
        let message = "TEST MESSAGE"
        description.append("\n\nMessage to sign: " + message)
        let PQSignature = try PQKey.signature(for: Data(message.utf8))
        let PQSignatureSize = PQSignature.count
        let ECSignature = try ECKey.signature(for: Data(message.utf8)).rawRepresentation
        let signature = PQSignature + ECSignature
        description.append("\nSignature contains \(signature.count) bytes")
        description.append("\nSignature: " + signature.subdata(in: 0..<32).base64EncodedString() + "...")

        // Verify the hybrid signature.
        let receivedPQSignature = signature.subdata(in: 0..<PQSignatureSize)
        let isValidPQSignature = PQKey.publicKey.isValidSignature(signature: receivedPQSignature, for: Data(message.utf8))
        let receivedECSignature = try P256.Signing.ECDSASignature(rawRepresentation: signature.subdata(in: PQSignatureSize..<signature.count))
        let isValidECSignature = ECKey.publicKey.isValidSignature(receivedECSignature, for: Data(message.utf8))
        if !(isValidPQSignature && isValidECSignature) {
            return (.fail, description + "\n❌ Signature verification failed")
        }
        description.append("\n✅ Signature verification succeeded")

        return (.pass, description)
    }
}
