/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a three phase animation example.
*/

import SwiftUI

private enum AnimationPhase: CaseIterable {
    case initial
    case move
    case scale
    
    var verticalOffset: Double {
        switch self {
        case .initial: 0
        case .move, .scale: -64
        }
    }
    
    var scaleEffect: Double {
        switch self {
        case .initial: 1
        case .move, .scale: 1.5
        }
    }
}

struct ThreePhaseAnimationView: View {
    var emoji: String
    @State private var likeCount = 1
    
    var body: some View {
        EmojiView(emoji: emoji)
            .phaseAnimator(AnimationPhase.allCases, trigger: likeCount) { content, phase in
                content
                    .scaleEffect(phase.scaleEffect)
                    .offset(y: phase.verticalOffset)
            } animation: { phase in
                switch phase {
                case .initial: .smooth
                case .move: .easeInOut(duration: 0.3)
                case .scale: .spring(duration: 0.3, bounce: 0.7)
                }
            }
            .onTapGesture {
                likeCount += 1
            }
    }
}

#Preview {
    ThreePhaseAnimationView(emoji: "❤️")
}
