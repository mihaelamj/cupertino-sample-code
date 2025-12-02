/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model that creates a custom catalog and returns the url to a dance video when matched.
*/

import Foundation
import ShazamKit

struct ResourcesProvider {
    
    static func catalog() throws -> SHCustomCatalog {

        let catalog = SHCustomCatalog()
        let url = Bundle.main.url(forResource: "ShazamKitDanceFinderCatalog", withExtension: UTType.shazamCustomCatalog.preferredFilenameExtension!)!
        try catalog.add(from: url)
        return catalog
    }
    
    static func videoURL(forFilename name: String) -> URL? {
        
        return Bundle.main.url(forResource: name, withExtension: UTType.quickTimeMovie.preferredFilenameExtension!)
    }
}
