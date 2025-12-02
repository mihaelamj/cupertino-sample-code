/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a two phase animation example.
*/

import SwiftUI

struct TwoPhaseAnimationView: View {
    var emoji: String
    @State private var likeCount = 1
    
    var body: some View {
        EmojiView(emoji: emoji)
            .phaseAnimator([false, true], trigger: likeCount) { content, phase in
                content.offset(y: phase ? -40.0 : 0.0)
            } animation: { phase in
                phase ? .bouncy : .default
            }
            .onTapGesture {
                likeCount += 1
            }
    }
}

#Preview {
    TwoPhaseAnimationView(emoji: "❤️")
}
