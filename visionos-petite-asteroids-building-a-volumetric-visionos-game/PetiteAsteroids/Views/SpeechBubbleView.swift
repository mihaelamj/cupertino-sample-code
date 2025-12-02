/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view showing a speech bubble with dialogue above the character.
*/

import SwiftUI
import RealityKit

struct SpeechBubbleView: View {
    var text: String
    var isDown: Bool = true

    var body: some View {
        Text(text)
            .padding()
            .background(.white)
            .foregroundStyle(.black)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(alignment: isDown ? .bottom : .top) {
                Image(systemName: isDown ? "arrowtriangle.down.fill" : "arrowtriangle.up.fill")
                    .font(.title)
                    .foregroundStyle(.white)
                    .offset(x: 0, y: isDown ? 18 : -18)
            }.frame(height: 100)
            .allowsHitTesting(false)
    }
}

struct SpeechBubbleAttachmentView: View {
    var speechBubbleEntity: Entity
    @State var scale = 0.0
    @State var opacity = 0.0

    var body: some View {
        if let speechBubble = speechBubbleEntity.observable.components[SpeechBubbleComponent.self] {
            SpeechBubbleView(text: speechBubble.text, isDown: speechBubble.isDown)
                .breakthroughEffect(.subtle)
                .scaleEffect(scale, anchor: speechBubble.isDown ? .bottom : .top)
                .opacity(opacity)
                .onChange(of: speechBubble.isEnabled) {
                    if speechBubble.isEnabled {
                        scale = 0.0
                        opacity = 1.0
                        withAnimation(Animation.spring(duration: 0.3, bounce: 0.25)) {
                            scale = Double(speechBubble.scale)
                        }
                    } else {
                        opacity = 1.0
                        scale = Double(speechBubble.scale)
                        withAnimation(Animation.easeIn(duration: 0.2)) {
                            opacity = 0.0
                        }
                    }
                }
        }
    }
}
