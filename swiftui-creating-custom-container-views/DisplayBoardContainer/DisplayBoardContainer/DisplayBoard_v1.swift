/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The first iteration of the main display board that may render with pinned cards.
*/

import SwiftUI

/// A display board container that draws data-driven content on cards pinned to
/// the board.
struct DisplayBoardV1<Data: RandomAccessCollection, Content: View>: View
    where Data.Element: Identifiable {
    /// The collection of data for generating the content of cards.
    var data: Data

    /// A view builder for mapping a data element to card content view.
    var content: (Data.Element) -> Content

    /// Creates a display board that represents the given collection, and maps each
    /// data element to a content view to draw on a card.
    init(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
    }

    var body: some View {
        DisplayBoardCardLayout {
            ForEach(data) { item in
                CardView {
                    content(item)
                }
            }
        }
        .padding(66)
        .background { DisplayBoardBackgroundView() }
    }
}

// MARK: - Previews

#Preview("Data-Driven DisplayBoard", traits: .landscapeLeft) {
    DisplayBoardV1(Songs.fromPerson1) { song in
        Text(song.title)
    }
    .ignoresSafeArea()
}
