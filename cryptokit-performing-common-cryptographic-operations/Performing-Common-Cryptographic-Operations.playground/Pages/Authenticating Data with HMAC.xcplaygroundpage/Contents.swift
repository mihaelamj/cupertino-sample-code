/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shows how to authenticate data with HMAC.
*/

/*:
 [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
 ****
 # Authenticating Data with HMAC
 
 Use a message authentication code (MAC) to authenticate data with symmetric key cryptography.
 For example, to verify that you’re authorized to upload a file to a server, the server might require you
 to attach a MAC created using a key that your app shares with the server.
 This tells the server that you uploaded the data, and that it remains unaltered from the time that you created the MAC.
 */
import CryptoKit
import Foundation

let filePath = Bundle.main.path(forResource: "ThemeSong", ofType: "aif")!
let audioData = FileManager.default.contents(atPath: filePath)!
/*:
 Create a random symmetric key. The sender and the receiver must share this key.
 */
let key = SymmetricKey(size: .bits256)

let authenticationCode = HMAC<SHA256>.authenticationCode(for: audioData, using: key)
print(authenticationCode)
/*:
 You often convert a MAC to data to send it over the network.
 */
let authenticationCodeData = Data(authenticationCode)
/*:
 If you receive a MAC, you can verify it without initializing a HashedAuthenticationCode.
 */
if HMAC<SHA256>.isValidAuthenticationCode(authenticationCodeData,
                                           authenticating: audioData, using: key) {
    print("The message authentication code is validating the audio data: \(audioData))")
}
/*:
 In order to protect against timing attacks, the comparison of a MAC with Data does not leak
 the shared prefix between the computed value and the value to be verified.
 */
assert(authenticationCode == authenticationCodeData)
/*:
 You can use any CryptoKit HashFunction, or type conforming to the HashFunction protocol, to generate an HMAC.
 */

let sha384MAC = HMAC<SHA384>.authenticationCode(for: audioData, using: key)
print(sha384MAC)
//: [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
