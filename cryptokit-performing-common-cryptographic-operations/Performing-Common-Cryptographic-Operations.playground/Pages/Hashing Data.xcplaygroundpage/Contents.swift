/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shows how to hash data.
*/

/*:
 [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
 ****
 # Hashing Data
 
 The output of a hash function, a digest, is a small data value that is virtually unique for a given input.
 The hash function’s collision resistance measures how unlikely it is for two different inputs to result in the same digest.
 Use the hash functions in CryptoKit to produce digests with excellent collision resistance.
 For example, you can create a digest that you transmit with a file to let the receiver verify that the file is intact.
 Even a single-bit error in the file during transmission results in the receiver computing a significantly different digest than the original.
 */
import CryptoKit
import Foundation

let filePath = Bundle.main.path(forResource: "ThemeSong", ofType: "aif")!
let audioData = FileManager.default.contents(atPath: filePath)!

let audioFileDigest = SHA256.hash(data: audioData)
print(audioFileDigest.description)
/*:
 When you can’t hold the entire object to be hashed in memory, initialize a hash function instance
 and then make multiple calls to the update(data:) function to compute the hash incrementally.
 */
var hasher = SHA256()

let fileStream = InputStream(fileAtPath: filePath)!
fileStream.open()
guard fileStream.streamStatus != .error else {
    let error = fileStream.streamError!
    fatalError("Couldn't open the file for streaming: \(error)")
}

defer {
    fileStream.close()
}

let bufferSize = 512
let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

while fileStream.hasBytesAvailable {
    let read = fileStream.read(buffer, maxLength: bufferSize)
    guard fileStream.streamStatus != .error else {
        let error = fileStream.streamError!
        fatalError("Couldn't read from the file stream: \(error)")
    }
    let bufferPointer = UnsafeRawBufferPointer(start: buffer, count: read)
    hasher.update(bufferPointer: bufferPointer)
}

let audioFileIterativeDigest = hasher.finalize()
print(audioFileIterativeDigest)

assert(audioFileDigest == audioFileIterativeDigest)
//: [Table of Contents](Table%20of%20Contents) | [Previous](@previous) | [Next](@next)
