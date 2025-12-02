/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions that assist in video processing and movie file handling.
*/

import AVFoundation

public struct RuntimeError: Error, CustomStringConvertible {
    public var description: String

    public init(_ description: String) {
        self.description = description
    }
}

/// Converts a four-character code to a string.
/// - Parameter code: A four-character code.
/// - Returns: A human-readable four-character code in a string.
public func fourCCToString(_ code: OSType) -> String? {
    if let byte1 = UnicodeScalar((code >> 24) & 0xFF),
        let byte2 = UnicodeScalar((code >> 16) & 0xFF),
        let byte3 = UnicodeScalar((code >> 8) & 0xFF),
        let byte4 = UnicodeScalar(code & 0xFF) {
        let str = String(Character(byte1)) + String(Character(byte2)) + String(Character(byte3)) + String(Character(byte4))
        return str
    }

    return nil
}

/// Determines the movie file type from the input movie file extension and updates the extension if necessary.
/// - Parameter moviePath: The movie file path that the person specified.
/// - Returns: A tuple that contains a possibly updated movie file path and file type.
public func updateMoviePathIfNecessaryAndGetFileType(_ moviePath: String) -> (moviePath: String, fileType: AVFileType) {
    let fileType: AVFileType
    var moviePathOut = moviePath

    if let index = moviePath.lastIndex(of: ".") {
        let fileExtension = String(moviePath[ index... ]).lowercased()

        switch fileExtension {
        case ".mov", ".qt":
            fileType = AVFileType.mov
        case ".m4v":
            fileType = AVFileType.m4v
        case ".mp4":
            fileType = AVFileType.mp4
        default:
            fileType = AVFileType.mov
            moviePathOut += ".mov"
        }
    } else {
        fileType = AVFileType.mov
        moviePathOut += ".mov"
    }

    return (moviePathOut, fileType)
}
