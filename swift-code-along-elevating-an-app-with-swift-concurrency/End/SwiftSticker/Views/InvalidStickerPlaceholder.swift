/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays an error placeholder when the system can't extract
  a sticker from a photo.
*/

import SwiftUI

struct InvalidStickerPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(Color.gray.quinary.shadow(.drop(color: .gray, radius: 15.0)))
            VStack {
                Image(systemName: "photo.badge.exclamationmark")
                Text("Unable to extract the sticker from the photo")
            }
            .opacity(0.6)
            .font(.largeTitle)
        }
        .padding()
    }
}
