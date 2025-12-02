/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The second iteration of the main display board that may render with pinned cards.
*/

import SwiftUI

/// A display board container that supports any kind of content, drawing each
/// piece of content on a card pinned to the board.
struct DisplayBoardV2<Content: View>: View {
    /// The content for the display board's cards.
    @ViewBuilder var content: Content

    var body: some View {
        DisplayBoardCardLayout {
            ForEach(subviews: content) { subview in
                CardView {
                    subview
                }
            }
        }
        .padding(66)
        .background { DisplayBoardBackgroundView() }
    }
}

// MARK: - Conveniences

// A convenience initializer for purely data-driven display boards, which is
// also source-compatible with the initializer for `DisplayBoardV1`.
extension DisplayBoardV2 {
    /// Creates a display board representing the given collection, mapping each
    /// data element to a content view to draw on a card.
    init<Data: RandomAccessCollection, C: View>(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> C
    ) where Data.Element: Identifiable,
        Content == ForEach<Data, Data.Element.ID, C> {
        self.init {
            ForEach(data, content: content)
        }
    }
}

// MARK: - Previews

#Preview("Static Content", traits: .landscapeLeft) {
    DisplayBoardV2 {
        Text("Song 1")
        Text("Song 2")
        Text("Song 3")
    }
    .ignoresSafeArea()
}

#Preview("Data-Driven Content", traits: .landscapeLeft) {
    DisplayBoardV2(Songs.fromPerson2) { song in
        Text(song.title)
    }
    .ignoresSafeArea()
}

#Preview("Compositional Content", traits: .landscapeLeft) {
    DisplayBoardV2 {
        Text("Song 1")
        Text("Song 2")
        Text("Song 3")

        ForEach(Songs.fromPerson2) { song in
            Text(song.title)
        }
    }
    .ignoresSafeArea()
}
