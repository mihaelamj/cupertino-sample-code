/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension of the sticker view data model for managing updates
  to its processed photos and cached data.
*/

import SwiftUI
import PhotosUI

extension StickerViewModel {
    var photosPickerSelection: Binding<[PhotosPickerItem]> {
        let selection = self.selection
        return Binding(
            get: { selection.map { $0.item } },
            set: { value in Task { @MainActor in
                self.selection = value.map { item in .init(item) }
            }
            }
        )
    }

    func getData(for item: SelectedPhoto) async -> Data {
        var data = try? await item.loadTransferable(type: Data.self)
        if let cachedData = getCachedData(for: item.id) { data = cachedData }
        cacheData(item.id, data!, updateState: false)
        return data!
    }

    func getCachedData(for id: SelectedPhoto.ID) -> Data? {
        if cachedSelection.contains(where: { $0 == id }) {
            try? Data(contentsOf: cachedDirectory.appendingPathComponent("\(id)"))
        } else { nil }
    }

    func cacheData(_ id: SelectedPhoto.ID, _ data: Data, updateState: Bool = true) {
        if updateState {
            updateProcessedPhotos()
            updateInvalidPhotos(for: id)
        }

        if !cachedSelection.contains(where: { $0 == id }) {
            cachedSelection.append(id)
            let url = cachedDirectory.appendingPathComponent("\(id)")
            try! data.write(to: url)
        }
    }

    var cachedSelection: [SelectedPhoto.ID] {
        get {
            UserDefaults.standard.array(
                forKey: "cachedSelection"
            ) as? [SelectedPhoto.ID] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "cachedSelection")
        }
    }

    private func updateProcessedPhotos() {
        processedPhotos = processedPhotos.filter { element in
            selection.contains(where: { $0.id == element.key })
        }
    }

    private func updateInvalidPhotos(for id: SelectedPhoto.ID) {
        if processedPhotos[id] == nil {
            invalidPhotos.append(id)
        }
    }

    private var cachedDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
}
