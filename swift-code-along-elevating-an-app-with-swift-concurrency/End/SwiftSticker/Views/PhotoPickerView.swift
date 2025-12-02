/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view displaying a photo picker of selected photos for creating stickers,
  if available; otherwise, a horizontally scrolling carousel of stickers.
*/

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    /// A view model for the list.
    @State var viewModel: StickerViewModel

    /// A container view for the list.
    var body: some View {
        if viewModel.selection.isEmpty {
            PhotosPicker(
                selection: viewModel.photosPickerSelection,
                matching: .images,
                preferredItemEncoding: .current,
                photoLibrary: .shared()
            ) {
                Text("Add Photos")
                    .font(.title)
            }
        } else {
            StickerCarousel(viewModel: viewModel)
        }
    }
}
