/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A sticker view data model for managing imported and processed photos,
  as well as their current state.
*/

import SwiftUI
import PhotosUI

@Observable
class StickerViewModel {
    /// An array of items for the picker's selected photos.
    var selection = [SelectedPhoto]()

    /// A dictionary that maps the photo ID to its processed version.
    var processedPhotos = [SelectedPhoto.ID: Image]()

    /// An array of photos that didn't process successfully.
    var invalidPhotos: [SelectedPhoto.ID] = []

    init() {
        if !cachedSelection.isEmpty {
            self.selection = cachedSelection.map {
                SelectedPhoto(itemIdentifier: $0)
            }
        }
    }

    func loadPhoto(_ item: SelectedPhoto) {
        var data: Data?

        if let cachedData = getCachedData(for: item.id) { data = cachedData }

        guard let data else { return }
        processedPhotos[item.id] = Image(data: data)

        cacheData(item.id, data)
    }
}
