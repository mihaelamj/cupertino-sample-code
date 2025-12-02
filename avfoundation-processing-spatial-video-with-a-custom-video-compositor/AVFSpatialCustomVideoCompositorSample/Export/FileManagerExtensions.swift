/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A simple file manager extension to provide the URL of the output file.
*/

import Foundation

extension FileManager {

    /// The output URL to write the exported movie file.
    var movieOutputURL: URL {
        let fileName = "\(UUID().uuidString).mov"
        return temporaryDirectory.appendingPathComponent(fileName)
    }
}
