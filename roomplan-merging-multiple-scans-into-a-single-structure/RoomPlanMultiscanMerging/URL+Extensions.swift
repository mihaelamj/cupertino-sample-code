/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities for identifying subfolders on disk.
*/

import Foundation

extension URL {
    
    /// A Boolean value that determines whether the URL references a folder on disk.
    var isDirectory: Bool {
        return (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }
    
    /// Provides all subfolders for the given file URL.
    var subDirectories: [URL] {
        guard isDirectory else { return [] }
        let urls = (try? FileManager.default.contentsOfDirectory(at: self,
                                                                 includingPropertiesForKeys: [.creationDateKey],
                                                                 options: [.skipsHiddenFiles]).filter(\.isDirectory)) ?? []
        let sortedURLS = urls.map { url in
            (url, (try? url.resourceValues(forKeys: [.creationDateKey]))?.creationDate ?? Date.distantPast)
        }
        .sorted(by: { $0.1 > $1.1 }) // Sort descending modification dates.
        .map { $0.0 } // Extract filenames.
        
        return sortedURLS
    }
}
