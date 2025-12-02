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
                            GradientSticker(processedPhoto: processedPhoto)
                        } else if viewModel.invalidPhotos.contains(selectedPhoto.id) {
                            InvalidStickerPlaceholder()
                        } else {
                            StickerPlaceholder()
                                .task {
                                    await viewModel.loadPhoto(selectedPhoto)
                                }
                        }
                    }
                    .containerRelativeFrame(.horizontal)
                    .visualEffect { [selection = viewModel.selection] content, proxy in
                        let frame = proxy.frame(in: .scrollView(axis: .horizontal))
                        let distance = min(0, frame.minX)
                        let isLast = selectedPhoto.id == selection.last?.id
                        
                        return content
                            .hueRotation(.degrees(frame.origin.x / 10))
                            .scaleEffect(1 + distance / 700)
                            .offset(x: isLast ? 0 : -distance / 1.25)
                            .brightness(-distance / 400)
                            .blur(radius: isLast ? 0 : -distance / 50)
                            .opacity(isLast ? 1.0 : min(1.0, 1.0 - (-distance / 400)))
                    }
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
