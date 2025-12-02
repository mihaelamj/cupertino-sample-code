/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view displaying a horizontally scrolling carousel of stickers, if available;
  otherwise, a photo picker to select a photo to process as a sticker image.
*/

import SwiftUI
import PhotosUI

struct StickerCarousel: View {
    @State var viewModel: StickerViewModel
    @State private var sheetPresented: Bool = false

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 16) {
                ForEach(viewModel.selection) { selectedPhoto in
                    VStack {
                        if let processedPhoto = viewModel.processedPhotos[selectedPhoto.id] {
                            processedPhoto
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 15.0))
                        } else if viewModel.invalidPhotos.contains(selectedPhoto.id) {
                            InvalidStickerPlaceholder()
                        } else {
                            StickerPlaceholder()
                        }
                    }
                    .containerRelativeFrame(.horizontal)
                }
            }
        }
        .configureCarousel(
            viewModel,
            sheetPresented: $sheetPresented
        )
        .sheet(isPresented: $sheetPresented) {
            StickerGrid(viewModel: viewModel)
        }
    }
}
