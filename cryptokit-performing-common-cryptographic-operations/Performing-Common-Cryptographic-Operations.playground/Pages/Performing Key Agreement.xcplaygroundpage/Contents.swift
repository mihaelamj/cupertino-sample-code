/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shows how to perform key agreement.
*/

/*:
 [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
 ****
 # Performing Key Agreement
 
 Use key agreement to establish a shared secret between two parties, each with their own private keys.
 
 The shared secret that you compute with elliptic curve key agreement is not itself suitable for use as a key
 because it’s not uniformly distributed. Instead, you derive a symmetric key from the secret.
 Include a salt value specific to your use case during key derivation.
 */
import CryptoKit
import Foundation

let protocolSalt = "CryptoKit Playgrounds Key Agreement".data(using: .utf8)!
/*:
 Generate a private key for Alice. Alice guards the private key closely, but publishes the corresponding public key.
 */
let alicePrivateKey = P256.KeyAgreement.PrivateKey()
let alicePublicKey = alicePrivateKey.publicKey
/*:
 Generate a private key for Bob. This happens on Bob’s device. The private key remains known only to Bob, but he publishes the public key.
 */
let bobPrivateKey = P256.KeyAgreement.PrivateKey()
let bobPublicKey = bobPrivateKey.publicKey
/*:
 Alice calculates a shared secret using her private key and Bob’s public key.
 */

let aliceSharedSecret = try! alicePrivateKey.sharedSecretFromKeyAgreement(with: bobPublicKey)

let aliceSymmetricKey = aliceSharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                                  salt: protocolSalt,
                                                                  sharedInfo: Data(),
                                                                  outputByteCount: 32)
/*:
 Bob does the same calculation on his device using his own private key and Alice’s public key.
 */

let bobSharedSecret = try! bobPrivateKey.sharedSecretFromKeyAgreement(with: alicePublicKey)

let bobSymmetricKey = bobSharedSecret.hkdfDerivedSymmetricKey(using: SHA256.self,
                                                              salt: protocolSalt,
                                                              sharedInfo: Data(),
                                                              outputByteCount: 32)
/*:
 Alice and Bob now have the same key that they can use for authentication or encryption.
 */
assert(bobSymmetricKey == aliceSymmetricKey)
//: [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
