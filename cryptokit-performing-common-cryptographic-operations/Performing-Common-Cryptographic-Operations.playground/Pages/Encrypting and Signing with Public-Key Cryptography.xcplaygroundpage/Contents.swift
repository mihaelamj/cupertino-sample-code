/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shows how to use public-key cryptography.
*/

/*:
 [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
 ****
 # Encrypting with Public-Key Cryptography
 
 Consider a case where a sender wants to send an encrypted message to a receiver,
 but sender and receiver don’t share a symmetric key.
 The sender knows the public encryption key of the receiver and the receiver optionally knows the authentication public key of the sender.
 The easiest way of performing that task is to use the
 [hybrid public key encryption (HPKE)](https://developer.apple.com/documentation/cryptokit/hpke) standard.

 The sender derives a symmetric encryption key, which it uses to encrypt the cleartext messages.
 It shares the symmetric key in an encapsulated form that the receiver can only use
 if it has the private key associated with the receiver's public encryption key.
 HPKE provides the receiver assurance that the ciphertext isn't tampered with,
 and can only be decrypted using the receiver's private key.

 The sender can attach additional cleartext data to ciphertext messages. Both the ciphertext and the additional cleartext are authenticated.
 */
import CryptoKit
import Foundation

// In order to encrypt, a ciphersuite is needed. CryptoKit provides a few safe defaults.
var ciphersuite = HPKE.Ciphersuite.P384_SHA384_AES_GCM_256

// This string identifies a particular use, with its own derivation schedule for the symmetric encryption key.
let protocolInfo = "CryptoKit Playgrounds Putting It Together".data(using: .utf8)!

// The private and public encryption key of the receiver
let recipientPrivateKey = P384.KeyAgreement.PrivateKey()
let recipientPublicKey = recipientPrivateKey.publicKey

/*:
 ## Public-Key Encryption with HPKE

 The `Sender` encrypts messages in base mode with a symmetric encryption key it derives using a key derivation function (KDF).
 
 */
var hpkeSender = try! HPKE.Sender(recipientKey: recipientPublicKey,
                                  ciphersuite: ciphersuite,
                                  info: protocolInfo)

let message = "I'm building a terrific new app!".data(using: .utf8)!
var ciphertext = try! hpkeSender.seal(message)
var encapsulatedKey = hpkeSender.encapsulatedKey

// Decrypting

var hpkeRecipient = try! HPKE.Recipient(privateKey: recipientPrivateKey,
                                        ciphersuite: ciphersuite,
                                        info: protocolInfo,
                                        encapsulatedKey: encapsulatedKey)

assert(try! hpkeRecipient.open(ciphertext) == message)
/*:
 ## Sender-Authenticated Public-Key Encryption with HPKE
 The `Sender` encrypts messages in authentication mode with a symmetric encryption key.
 
 If the receiver knows the authentication public key of the sender,
 then the sender can use the corresponding private key to authenticate that they created the ciphertext messages,
 by using HPKE in an authentication mode.
 */
let senderPrivateKey = P384.KeyAgreement.PrivateKey()
let senderPublicKey = senderPrivateKey.publicKey

hpkeSender = try! HPKE.Sender(recipientKey: recipientPublicKey,
                              ciphersuite: ciphersuite,
                              info: protocolInfo,
                              authenticatedBy: senderPrivateKey)

ciphertext = try! hpkeSender.seal(message)
encapsulatedKey = hpkeSender.encapsulatedKey

// Decrypting

hpkeRecipient = try! HPKE.Recipient(privateKey: recipientPrivateKey,
                                    ciphersuite: ciphersuite,
                                    info: protocolInfo,
                                    encapsulatedKey: encapsulatedKey,
                                    authenticatedBy: senderPublicKey)

assert(try! hpkeRecipient.open(ciphertext) == message)
/*:
 ## PSK-Authenticated Public-Key Encryption with HPKE
 
 The `Sender` encrypts messages in PSK mode using a symmetric encryption key that the sender and recipient both know in advance,
 in combination with a key it derives using a key derivation function (KDF)
 and the key schedule data in `info`.
 
 */
let psk = SymmetricKey(size: .bits256)
let pskID = Data(UUID().uuidString.utf8)

hpkeSender = try! HPKE.Sender(recipientKey: recipientPublicKey,
                              ciphersuite: ciphersuite,
                              info: protocolInfo,
                              presharedKey: psk,
                              presharedKeyIdentifier: pskID)

ciphertext = try! hpkeSender.seal(message)
encapsulatedKey = hpkeSender.encapsulatedKey

// Decrypting

hpkeRecipient = try! HPKE.Recipient(privateKey: recipientPrivateKey,
                                    ciphersuite: ciphersuite,
                                    info: protocolInfo,
                                    encapsulatedKey: encapsulatedKey,
                                    presharedKey: psk,
                                    presharedKeyIdentifier: pskID)

assert(try! hpkeRecipient.open(ciphertext) == message)

/*:
 ## Sending and receiving streams of ciphertext
 
 You can use a single `Sender` to encrypt a stream of messages that you decrypt with a single `Recipient`.
 The `Recipient` needs to decrypt the ciphertext messages in the same order that the `Sender` encrypts the cleartext messages.
 */
let messageStream = [
    "I'm building a terrific new app!".data(using: .utf8)!,
    "My app sends and receives encrypted messages.".data(using: .utf8)!
]

let streamInfo = "Encrypting a different stream of messages".data(using: .utf8)!
hpkeSender = try! HPKE.Sender(recipientKey: recipientPublicKey,
                              ciphersuite: ciphersuite,
                              info: streamInfo)
encapsulatedKey = hpkeSender.encapsulatedKey

let ciphertextStream = messageStream.map { plaintext in
    try! hpkeSender.seal(plaintext)
}

// Decrypting

hpkeRecipient = try! HPKE.Recipient(privateKey: recipientPrivateKey,
                                    ciphersuite: ciphersuite,
                                    info: streamInfo,
                                    encapsulatedKey: encapsulatedKey)

let cleartextStream = ciphertextStream.map { ciphertext in
    try! hpkeRecipient.open(ciphertext)
}

assert(cleartextStream == messageStream)

/*:
 ## Key-Agreement only with HPKE

 You can also use HPKE to derive a symmetric key, and then perform custom operations on it.
 You use each derived secret you export for a single purpose,
 for example to use as the pre-shared key when you establish a channel using the QUIC protocol.
 
 */
ciphersuite = HPKE.Ciphersuite(kem: .P384_HKDF_SHA384, kdf: .HKDF_SHA256, aead: .exportOnly)

hpkeSender = try! HPKE.Sender(recipientKey: recipientPublicKey,
                              ciphersuite: ciphersuite,
                              info: protocolInfo)
let symmetricKey = try hpkeSender.exportSecret(context: Data("QUIC-SharedSecret".utf8), outputByteCount: 32)

//: [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
