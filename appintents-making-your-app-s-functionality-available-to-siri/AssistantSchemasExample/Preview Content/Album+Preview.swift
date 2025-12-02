/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that provides sample data to be used with SwiftUI previews
*/

import Photos
import SwiftData

extension Album {
    
    static var preview: Album {
        let collection = PHAssetCollection()
        let album = Album(collection: collection)
        return album
    }
}
