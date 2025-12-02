/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows different animation examples.
*/

import SwiftUI

struct ContentView: View {
    @State private var emojis = ["🔥", "❤️", "🤩"]
    
    var body: some View {
        VStack(spacing: 100) {
            VStack {
                HStack {
                    ForEach(emojis, id: \.self) { emoji in
                        SimpleAnimationView(emoji: emoji)
                    }
                }
                Text("Simple Animation")
            }

            VStack {
                HStack {
                    ForEach(emojis, id: \.self) { emoji in
                        TwoPhaseAnimationView(emoji: emoji)
                    }
                }
                Text("Two Phase Animation")
            }

            VStack {
                HStack {
                    ForEach(emojis, id: \.self) { emoji in
                        ThreePhaseAnimationView(emoji: emoji)
                    }
                }
                Text("Three Phase Animation")
            }

            VStack {
                HStack {
                    ForEach(emojis, id: \.self) { emoji in
                        KeyframeAnimationView(emoji: emoji)
                    }
                }
                Text("Keyframe Animation")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
