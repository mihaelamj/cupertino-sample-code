/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation for the Guess Together view modifier.
*/

import SwiftUI

struct GuessTogetherToolbarModifier: ViewModifier {
    @Environment(AppModel.self) var appModel
    
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "figure.run.square.stack.fill")
                            .foregroundStyle(.purple.gradient)
                        Text("Guess Together!")
                    }
                    .font(.largeTitle)
                    .italic()
                }
                
            }
            .toolbarRole(.navigationStack)
    }
}

// A convenience custom modifier wrapper.
extension View {
    func guessTogetherToolbar() -> some View {
        return modifier(GuessTogetherToolbarModifier())
    }
}
