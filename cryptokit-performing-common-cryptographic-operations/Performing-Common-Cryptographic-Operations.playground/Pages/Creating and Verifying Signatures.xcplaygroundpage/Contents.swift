/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shows how to create and verify signatures.
*/

/*:
 [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
 ****
 # Creating and Verifying Signatures
 
 Use a private key to sign data. Anyone with the corresponding public key can verify the signature.
 Start by generating a random key:
 */
import CryptoKit
let signingKey = Curve25519.Signing.PrivateKey()
/*:
 Get a data representation of the public key, which you publish freely.
 */
let signingPublicKey = signingKey.publicKey
let signingPublicKeyData = signingPublicKey.rawRepresentation
/*:
 Initialize a public key from its raw representation.
 */
let initializedSigningPublicKey = try! Curve25519.Signing.PublicKey(rawRepresentation: signingPublicKeyData)
/*:
 Use the private key to generate a signature.
 */
let dataToSign = "Some sample Data to sign.".data(using: .utf8)!
let signature = try! signingKey.signature(for: dataToSign)
/*:
 Verify the signature with the public key.
 */
if initializedSigningPublicKey.isValidSignature(signature, for: dataToSign) {
    print("The signature is valid.")
}
//: [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
