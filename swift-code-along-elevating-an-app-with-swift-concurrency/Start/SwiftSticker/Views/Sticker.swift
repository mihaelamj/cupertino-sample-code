/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view displaying a sticker, if available; otherwise, a placeholder image
  representing an error.
*/

import SwiftUI

struct Sticker: View {
    init(_ image: Image?) {
        self.sticker = image
    }

    init(_ processedPhoto: ProcessedPhoto?) {
        self.sticker = processedPhoto?.sticker
    }

    let sticker: Image?

    var body: some View {
        Group {
            if let sticker {
                sticker
                    .resizable()
            } else {
                errorSticker
            }
        }
        .scaledToFit()
        .frame(minHeight: 80)
        .shadow(radius: 2)
    }

    @ViewBuilder
    var errorSticker: some View {
        Image(systemName: "exclamationmark.triangle.fill")
            .resizable()
            .padding(16)
            .foregroundStyle(.yellow)
    }
}
