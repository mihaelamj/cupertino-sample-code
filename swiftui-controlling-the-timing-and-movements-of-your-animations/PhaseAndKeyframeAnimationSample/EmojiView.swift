/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a provided emoji.
*/

import SwiftUI

struct EmojiView: View {
    var emoji: String
    
    var body: some View {
        Text(emoji)
            .font(.largeTitle)
    }
}

#Preview {
    EmojiView(emoji: "❤️")
}
