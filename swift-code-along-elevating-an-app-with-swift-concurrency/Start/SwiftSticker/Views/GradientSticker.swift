/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view displaying a sticker with a vertical linear gradient overlay based on
  the color scheme that the system extracts from its processed image.
*/

import SwiftUI

struct GradientSticker: View {
    /// An image that a person selects in the Photos picker.
    @State var processedPhoto: ProcessedPhoto

    /// A container view for the row.
    var body: some View {
        VStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: processedPhoto.colorScheme.colors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.7)

                VStack(spacing: 16) {
                    processedPhoto.sticker
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 15.0))
        }
    }
}
