/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Support for testing post-quantum HPKE keys.
*/

import Foundation
import CryptoKit

@available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, *)
extension KeyTest {
    /// Tests the PQ-HPKE key of the given type.
    internal func testPQHPKE(type: PQHPKEType) throws -> (TestStatus, String) {
        switch type {
        case .XWingMLKEM768X25519:
            return try check(try XWingMLKEM768X25519.PrivateKey(), ciphersuite: .XWingMLKEM768X25519_SHA256_AES_GCM_256)
        }
    }

    private func check<SK: KEMPrivateKey & GenericPasswordConvertible & HPKEKEMPrivateKey>(_ key: SK, ciphersuite: HPKE.Ciphersuite)
    throws -> (TestStatus, String) {
        var description = key.description

        // The sender makes the encapsulation.
        let info = "INFO"
        description.append("\n\nHPKE info: " + info)
        var sender = try HPKE.Sender(recipientKey: key.publicKey, ciphersuite: ciphersuite, info: Data(info.utf8))
        let encapsulation = sender.encapsulatedKey
        description.append("\nEncapsulation contains \(encapsulation.count) bytes.")
        description.append("\nEncapsulation: " + encapsulation.subdata(in: 0..<32).base64EncodedString() + "...")

        // The recipient receives the encapsulation.
        var recipient = try HPKE.Recipient(privateKey: key, ciphersuite: ciphersuite, info: Data(info.utf8), encapsulatedKey: encapsulation)

        // Check that the shared secrets match.
        let context = Data("\n\nCONTEXT".utf8)
        if try sender.exportSecret(context: context, outputByteCount: 16) != recipient.exportSecret(context: context, outputByteCount: 16) {
            return (.fail, description + "\n❌ Shared secret mismatch")
        }
        description.append("\n✅ Shared secret match")

        // The sender encrypts the message.
        let message = "MESSAGE"
        let authenticatedMetadata = "METADATA"
        description.append("\n\nMessage: " + message)
        description.append("\nAuthenticated metadata: " + authenticatedMetadata)
        let ciphertext = try sender.seal(Data(message.utf8), authenticating: Data(authenticatedMetadata.utf8))
        description.append("\nCiphertext: " + ciphertext.base64EncodedString())

        // The recipient decrypts the message.
        let decryption = try recipient.open(ciphertext, authenticating: Data(authenticatedMetadata.utf8))
        description.append("\nDecryption: " + decryption.base64EncodedString())
        if decryption != Data(message.utf8) {
            return (.fail, description + "\n❌ Decryption mismatch")
        }
        description.append("\n✅ Decryption match")

        return (.pass, description)
    }
}
