/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a grid of information about the contenders.
*/

import SwiftUI

/// A view that shows a grid of information about the contenders.
///
/// This view demonstrates how to use a
/// [`Grid`](https://developer.apple.com/documentation/swiftui/grid) by
/// drawing a leaderboard that shows vote counts and percentages.
///
/// ![A grid with three rows and three columns. The first column and last column
/// each contain rectangles in every cell. The middle column contains progress
/// indicators with different amounts of progress.](leaderboard)
///
/// The grid contains a
/// [`GridRow`](https://developer.apple.com/documentation/swiftui/gridrow) inside a
/// [`ForEach`](https://developer.apple.com/documentation/swiftui/foreach),
/// where each view in the row creates a column cell. So the first view appears
/// in the first column, the second in the second column, and so on. Because the
/// [`Divider`](https://developer.apple.com/documentation/swiftui/divider)
/// appears outside of a grid row instance, it creates a
/// row that spans the width of the grid.
///
/// ```swift
/// Grid(alignment: .leading) {
///     ForEach(model.pets) { pet in
///         GridRow {
///             Text(pet.type)
///             ProgressView(
///                 value: Double(pet.votes),
///                 total: Double(max(1, model.totalVotes))) // Avoid dividing by zero.
///             Text("\(pet.votes)")
///                 .gridColumnAlignment(.trailing)
///         }
///
///         Divider()
///     }
/// }
/// ```
///
/// The leaderboard initializes the grid with leading-edge alignment, which
/// applies to every cell in the grid. Meanwhile, the
/// [`gridColumnAlignment(_:)`](https://developer.apple.com/documentation/swiftui/view/gridcolumnalignment(_:))
/// view modifier that appears on the vote count cell overrides the alignment
/// of cells in that column to use trailing-edge alignment.
///
/// - Tag: Leaderboard
struct Leaderboard: View {
    @EnvironmentObject private var model: Model

    var body: some View {
        Grid(alignment: .leading) {
            ForEach(model.pets) { pet in
                GridRow {
                    Text(pet.type)
                    ProgressView(
                        value: Double(pet.votes),
                        total: Double(max(1, model.totalVotes))) // Avoid dividing by zero.
                    Text("\(pet.votes)")
                        .gridColumnAlignment(.trailing)
                }

                Divider()
            }
        }
        .padding()
    }
}

/// A SwiftUI preview provider for the leaderboard view.
struct Leaderboard_Previews: PreviewProvider {
    static var previews: some View {
        Leaderboard()
            .environmentObject(Model.previewData)
    }
}
