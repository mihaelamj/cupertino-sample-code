/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A wrapper for `PhotosPickerItem` that conforms to `Identifiable`.
*/

import SwiftUI
import PhotosUI

/// An `Identifiable` type that stores a `PhotosPickerItem`.
///
/// `SelectedPhoto` wraps a `PhotosPickerItem` and extracts or generates a stable identifier
/// to enable its use in contexts that require unique identification.
///
/// - Properties:
///   - `id`: A unique string identifier extracted from the photo item or generated if not available
///   - `item`: The underlying `PhotosPickerItem` being wrapped
struct SelectedPhoto: Identifiable {
    typealias ID = String

    let id: ID
    let item: PhotosPickerItem

    init(itemIdentifier: ID) {
        self.init(PhotosPickerItem(itemIdentifier: itemIdentifier))
    }

    init(_ item: PhotosPickerItem) {
        self.item = item
        if let id = item.itemIdentifier?.split(separator: "/").first {
            self.id = String(id)
        } else {
            self.id = UUID().uuidString
        }
    }

    func loadTransferable<T: Transferable & Sendable>(type: T.Type) async throws -> sending T? {
        try await item.loadTransferable(type: T.self)
    }
}
