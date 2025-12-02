/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The third iteration of the main display board that render with pinned cards.
*/

import SwiftUI

/// A display board container that supports any kind of content, drawing each
/// piece of content on a card pinned to the board.
///
/// If the board contains more than 15 cards, each card appears in a
/// smaller size.
struct DisplayBoardV3<Content: View>: View {
    /// The content for the display board's cards.
    @ViewBuilder var content: Content

    var body: some View {
        DisplayBoardCardLayout {
            Group(subviews: content) { subviews in
                ForEach(subviews) { subview in
                    CardView(scale: subviews.count > 15 ? .small : .normal) {
                        subview
                    }
                }
            }
        }
        .padding(66)
        .background { DisplayBoardBackgroundView() }
    }
}

// MARK: - Previews

#Preview("Normal Display Board", traits: .landscapeLeft) {
    DisplayBoardV3 {
        Text("Song 1")
        Text("Song 2")
        Text("Song 3")

        ForEach(Songs.fromPerson2) { song in
            Text(song.title)
        }
    }
    .ignoresSafeArea()
}

#Preview("Crowded Display Board", traits: .landscapeLeft) {
    DisplayBoardV3 {
        Text("Song 1")
        Text("Song 2")
        Text("Song 3")

        ForEach(Songs.fromPerson2) { song in
            Text(song.title)
        }

        ForEach(Songs.fromPerson3) { song in
            Text(song.title)
        }
    }
    .ignoresSafeArea()
}
