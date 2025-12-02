/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows an animation example using animations that SwiftUI provides.
*/

import SwiftUI

struct SimpleAnimationView: View {
    var emoji: String
    @State private var offset = 0.0

    var body: some View {
        EmojiView(emoji: emoji)
            .offset(y: offset)
            .onTapGesture {
                withAnimation(.bouncy) {
                    offset = -40.0
                } completion: {
                    withAnimation {
                        offset = 0.0
                    }
                }
            }
    }
}

#Preview {
    SimpleAnimationView(emoji: "❤️")
}
