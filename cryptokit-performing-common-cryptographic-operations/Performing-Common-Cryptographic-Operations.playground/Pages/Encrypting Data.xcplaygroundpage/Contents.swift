/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shows how to encrypt data.
*/

/*:
 [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
 ****
 # Encrypting Data
 
 When you need both authentication and confidentiality, use authenticated encryption.
 */
/*:
 The server encrypts using a randomly generated key.
 */
import CryptoKit
import Foundation

let key = SymmetricKey(size: .bits256)

let themeSongPath = Bundle.main.path(forResource: "ThemeSong", ofType: "aif")!
let themeSong = FileManager.default.contents(atPath: themeSongPath)!

let encryptedContent = try! ChaChaPoly.seal(themeSong, using: key).combined
/*:
 The client decrypts using the same key, assumed to have been obtained out-of-band.
 */
let sealedBox = try! ChaChaPoly.SealedBox(combined: encryptedContent)

let decryptedThemeSong = try! ChaChaPoly.open(sealedBox, using: key)

assert(decryptedThemeSong == themeSong)
/*:
 You use a sealed box to hold the three outputs of the encryption operation: a nonce, the ciphertext, and a tag.
 */
// The nonce should be unique per encryption operation.
// Some protocols require specific values to be used, such as monotonically increasing counters.
// If none is passed during the during the encryption, CryptoKit randomly generates a safe value for you.
let nonce = sealedBox.nonce

// The ciphertext is the encrypted plaintext, and is the same size as the original data.
let ciphertext = sealedBox.ciphertext

// The tag provides authentication.
let tag = sealedBox.tag

// The combined property holds the collected nonce, ciphertext and tag.
assert(sealedBox.combined == nonce + ciphertext + tag)
//: [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
