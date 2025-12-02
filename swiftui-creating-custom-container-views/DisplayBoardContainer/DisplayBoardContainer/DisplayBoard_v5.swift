/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The fifth iteration of the main display board which may render with pinned cards.
*/

import SwiftUI

/// A display board container that supports any kind of content, including
/// sections, drawing each piece of content on a card pinned to the board.
///
/// If the board contains more than 15 cards, each card appears in a
/// smaller size.
///
/// To cross off a card, apply the `displayBoardCardRejected()`
/// modifier to its content and pass a value of `true`.
struct DisplayBoardV5<Content: View>: View {
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
                                let values = subview.containerValues
                                CardView(
                                    scale: cardScale(forSections: sections),
                                    isRejected: values.isDisplayBoardCardRejected,
                                    rotation: values.displayBoardCardRotation,
                                    pinColor: values.displayBoardCardPinColor
                                ) {
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

    private func cardScale(forSections sections: SectionCollection)
        -> DisplayBoardCardScale {
        if sections.count > 1 {
            // When there's more than one section, always use the small scale
            // to conserve space.
            return .small
        } else {
            // When there's only one section, use the small scale only if the
            // board gets too crowded.
            if let section = sections.first, section.content.count > 15 {
                return .small
            } else {
                return .normal
            }
        }
    }
}

// MARK: - Container Values

extension ContainerValues {
    @Entry var isDisplayBoardCardRejected: Bool = false
    @Entry var displayBoardCardPinColor: Color?
    @Entry var displayBoardCardPosition: UnitPoint?
    @Entry var displayBoardCardRotation: Angle?
}

extension View {
    func displayBoardCardRejected(_ isRejected: Bool) -> some View {
        containerValue(\.isDisplayBoardCardRejected, isRejected)
    }

    func displayBoardCardPinColor(_ pinColor: Color?) -> some View {
        containerValue(\.displayBoardCardPinColor, pinColor)
    }

    func displayBoardCardPosition(_ position: UnitPoint?) -> some View {
        containerValue(\.displayBoardCardPosition, position)
    }

    func displayBoardCardRotation(_ rotation: Angle?) -> some View {
        containerValue(\.displayBoardCardRotation, rotation)
    }
}

// MARK: - Previews

#Preview("Rejected Cards", traits: .landscapeLeft) {
    DisplayBoardV5 {
        Section("Person1’s\nFavorites") {
            Text("Song 1")
                .displayBoardCardRejected(true)
            Text("Song 2")
            Text("Song 3")
        }
        Section("Person2’s\nFavorites") {
            ForEach(Songs.fromPerson2) { song in
                Text(song.title)
                    .displayBoardCardRejected(song.person2CalledDibs)
            }
        }
        Section("Person3’s\nFavorites") {
            ForEach(Songs.fromPerson3) { song in
                Text(song.title)
            }
        }
        .displayBoardCardRejected(true)
    }
    .ignoresSafeArea()
}
