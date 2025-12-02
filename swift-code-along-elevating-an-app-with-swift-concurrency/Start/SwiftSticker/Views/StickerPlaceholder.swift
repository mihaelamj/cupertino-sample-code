/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view used as a placeholder when loading a sticker.
*/

import SwiftUI

struct StickerPlaceholder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15.0)
                .fill(Color.gray.quinary.shadow(.drop(color: .gray, radius: 15.0)))
            ProgressView()
        }
    }
}
