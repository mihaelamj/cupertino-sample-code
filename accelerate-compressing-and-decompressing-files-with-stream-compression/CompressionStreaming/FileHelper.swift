/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A set of static functions that simplify file handling.
*/

import Foundation

class FileHelper {
    
    // Returns the URL for a given file name in the app's
    // temporary directory.
    static func urlFor(fileNameInTempDirectory: String) -> URL? {
        let tempDirURL = URL(fileURLWithPath: NSTemporaryDirectory())
        
        return tempDirURL.appendingPathComponent(fileNameInTempDirectory)
    }
    
    // Returns the size of a file, in bytes, at the specified URL.
    static func fileSize(atURL url: URL) -> UInt64? {
        let attributesOfItem = try? FileManager.default.attributesOfItem(atPath: url.path)
        let sourceLength = (attributesOfItem as NSDictionary?)?.fileSize()
        
        return sourceLength
    }
}

extension FileHandle {
    // Returns a writable file handle for a given file name in the app's
    // temporary directory.
    static func makeFileHandle(forWritingToFileNameInTempDirectory: String) -> FileHandle? {
        guard
            let url = FileHelper.urlFor(fileNameInTempDirectory: forWritingToFileNameInTempDirectory) else {
                return nil
        }
        
        FileManager.default.createFile(atPath: url.path,
                                       contents: nil,
                                       attributes: nil)
        
        return try? self.init(forWritingTo: url)
    }
}
