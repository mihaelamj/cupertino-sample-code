/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A scrollable view that uses a two-column layout to display a grid of stickers.
*/

import SwiftUI

struct GridContent: View {
    let viewModel: StickerViewModel

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(viewModel.selection) { selectedPhoto in
                    Sticker(viewModel.processedPhotos[selectedPhoto.id]!)
                }
            }
            .padding()
        }
    }
}
