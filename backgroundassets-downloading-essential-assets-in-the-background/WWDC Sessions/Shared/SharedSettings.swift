/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Settings shared between the app and extension.
*/

import Foundation

class SharedSettings {
    
    static let appGroupIdentifier = {
        guard let infoDictionary = Bundle.main.infoDictionary,
              let identifier = infoDictionary["AppGroupIdentifier"] as? String else {
            fatalError("Failed to retrieve App Group Identifier from Info.plist.")
        }

        return identifier
    }()

    static let sharedResourcesURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)!
    
    static let sessionStorageURL = {
        let url = sharedResourcesURL.appending(components: "Library", "Caches", "Sessions", directoryHint: .isDirectory)
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            fatalError("Failed to create session storage directory: \(error)")
        }
        
        return url
    }()
    
    static let localManifestURL = sessionStorageURL.appending(path: "manifest.plist")
}
