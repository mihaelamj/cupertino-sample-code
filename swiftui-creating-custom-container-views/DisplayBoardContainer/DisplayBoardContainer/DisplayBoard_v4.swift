/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The fourth iteration of the main display board that may render with pinned cards.
*/

import SwiftUI

/// A display board container that supports any kind of content, including
/// sections, drawing each piece of content on a card pinned to the board.
///
/// If the board contains more than 15 cards, each card appears in a
/// smaller size.
struct DisplayBoardV4<Content: View>: View {
    /// The content for the display board's cards.
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: 22) {
            Group(sections: content) { sections in
                ForEach(sections) { section in
                    VStack(spacing: 20) {
                        // Only show a header card if the header has content.
                        if !section.header.isEmpty {
                            HeaderCardView {
                                section.header
                            }
                        }

                        DisplayBoardSectionCardLayout {
                            ForEach(section.content) { subview in
                                CardView(scale: .small) {
                                    subview
                                }
                            }
                        }
                        .background {
                            // Only show a section background if there are
                            // multiple sections, since the purpose of the
                            // background is to help visually distinguish the
                            // sections.
                            if sections.count > 1 {
                                DisplayBoardSectionBackgroundView()
                            }
                        }

                        // Only show a footer card if the footer has content.
                        if !section.footer.isEmpty {
                            FooterCardView {
                                section.footer
                            }
                            .padding(.horizontal, 10)
                        }
                    }
                }
            }
        }
        .padding(66)
        .background { DisplayBoardBackgroundView() }
    }
}

// MARK: - Previews

#Preview("Sections", traits: .landscapeLeft) {
    DisplayBoardV4 {
        Section {
            Text("Song 1")
            Text("Song 2")
            Text("Song 3")
        }
        Section {
            ForEach(Songs.fromPerson2) { song in
                Text(song.title)
            }
        }
        Section {
            ForEach(Songs.fromPerson3) { song in
                Text(song.title)
            }
        }
    }
    .ignoresSafeArea()
}

#Preview("Sections with Headers", traits: .landscapeLeft) {
    DisplayBoardV4 {
        Section("Person1’s\nFavorites") {
            Text("Song 1")
            Text("Song 2")
            Text("Song 3")
        }
        Section("Person2’s\nFavorites") {
            ForEach(Songs.fromPerson2) { song in
                Text(song.title)
            }
        }
        Section("Person3’s\nFavorites") {
            ForEach(Songs.fromPerson3) { song in
                Text(song.title)
            }
        }
    }
    .ignoresSafeArea()
}

#Preview("Sections with Headers & Footers", traits: .landscapeLeft) {
    DisplayBoardV4 {
        Section {
            Text("Song 1")
            Text("Song 2")
            Text("Song 3")
        } header: {
            Text("Person1’s\nFavorites")
        } footer: {
            Text("A few of Person1’s favorite songs")
        }

        Section {
            ForEach(Songs.fromPerson2) { song in
                Text(song.title)
            }
        } header: {
            Text("Person2’s\nFavorites")
        } footer: {
            Text("Recommended songs from Person2")
        }

        Section {
            ForEach(Songs.fromPerson3) { song in
                Text(song.title)
            }
        } header: {
            Text("Person3’s\nFavorites")
        } footer: {
            Text("Person3’s suggestions")
        }
    }
    .ignoresSafeArea()
}
