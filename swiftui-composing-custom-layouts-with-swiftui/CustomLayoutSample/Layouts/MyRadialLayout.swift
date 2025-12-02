/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom layout that arranges its views in a circle.
*/

import SwiftUI

/// A custom layout that arranges its views in a circle.
///
/// This container works as a general radial layout for any number of views.
/// If you provide exactly three views in the layout's view builder and give
/// the views rank values using the `Rank` view layout key, the layout rotates
/// the view positions so that the views appear in rank order from top to
/// bottom.
///
/// ![Three filled circles placed at equal distances along the outline of a
/// larger, empty circle. The outline of the larger circle uses a dashed
/// line.](avatars)
///
/// Like other custom layouts, this layout implements the two required methods.
/// For ``sizeThatFits(proposal:subviews:cache:)``, the layout fills the
/// available space by returning whatever size its container proposes.
/// The layout uses the proposal's
/// [`replacingUnspecifiedDimensions(by:)`](https://developer.apple.com/documentation/swiftui/proposedviewsize/replacingunspecifieddimensions(by:))
/// method to convert the proposal into a concrete size:
///
/// ```swift
/// proposal.replacingUnspecifiedDimensions()
/// ```
///
/// Then, in the ``placeSubviews(in:proposal:subviews:cache:)`` method, the
/// layout rotates a vector, translates the vector to the middle of the
/// placement region, and uses that as the anchor for the subview:
///
/// ```swift
/// for (index, subview) in subviews.enumerated() {
///     // Find a vector with an appropriate size and rotation.
///     var point = CGPoint(x: 0, y: -radius)
///         .applying(CGAffineTransform(
///             rotationAngle: angle * Double(index) + offset))
///
///     // Shift the vector to the middle of the region.
///     point.x += bounds.midX
///     point.y += bounds.midY
///
///     // Place the subview.
///     subview.place(at: point, anchor: .center, proposal: .unspecified)
/// }
/// ```
///
/// The offset that the layout applies to the rotation accounts for the current
/// rankings, placing higher-ranked pets closer to the top of the interface. The
/// app stores ranks on the subviews using the
/// [`LayoutValueKey`](https://developer.apple.com/documentation/swiftui/layoutvaluekey)
/// protocol, and then reads the values to calculate the offset before placing
/// views.
struct MyRadialLayout: Layout {
    /// Returns a size that the layout container needs to arrange its subviews
    /// in a circle.
    ///
    /// This implementation uses whatever space the container view proposes.
    /// If the container asks for this layout's ideal size, it offers the
    /// the [`unspecified`](https://developer.apple.com/documentation/swiftui/proposedviewsize/unspecified)
    /// proposal, which contains `nil` in each dimension.
    /// To convert that to a concrete size, this method uses the proposal's
    /// [`replacingUnspecifiedDimensions(by:)`](https://developer.apple.com/documentation/swiftui/proposedviewsize/replacingunspecifieddimensions(by:))
    /// method.
    /// - Tag: sizeThatFitsRadial
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        // Take whatever space is offered.
        proposal.replacingUnspecifiedDimensions()
    }

    /// Places the stack's subviews in a circle.
    /// - Tag: placeSubviewsRadial
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        // Place the views within the bounds.
        let radius = min(bounds.size.width, bounds.size.height) / 3.0

        // The angle between views depends on the number of views.
        let angle = Angle.degrees(360.0 / Double(subviews.count)).radians

        // Read the ranks from each view, and find the appropriate offset.
        // This only has an effect for the specific case of three views with
        // nonuniform rank values. Otherwise, the offset is zero, and it has
        // no effect on the placement.
        let ranks = subviews.map { subview in
            subview[Rank.self]
        }
        let offset = getOffset(ranks)

        for (index, subview) in subviews.enumerated() {
            // Find a vector with an appropriate size and rotation.
            var point = CGPoint(x: 0, y: -radius)
                .applying(CGAffineTransform(
                    rotationAngle: angle * Double(index) + offset))

            // Shift the vector to the middle of the region.
            point.x += bounds.midX
            point.y += bounds.midY

            // Place the subview.
            subview.place(at: point, anchor: .center, proposal: .unspecified)
        }
    }
}

extension MyRadialLayout {
    /// Finds the angular offset that arranges the views in rank order.
    ///
    /// This method produces an offset that tells a radial layout how much
    /// to rotate all of its subviews so that they display in order, from
    /// top to bottom, according to their ranks. The method only has meaning
    /// for exactly three laid-out views, initially positioned with the first
    /// view at the top, the second at the lower right, and the third in the
    /// lower left of the radial layout.
    ///
    /// - Parameter ranks: The rank values for the three subviews. Provide
    ///   exactly three ranks.
    ///
    /// - Returns: An angle in radians. The method returns zero if you provide
    ///   anything other than three ranks, or if the ranks are all equal,
    ///   representing a three-way tie.
    private func getOffset(_ ranks: [Int]) -> Double {
        guard ranks.count == 3,
              !ranks.allSatisfy({ $0 == ranks.first }) else { return 0.0 }

        // Get the offset as a fraction of a third of a circle.
        // Put the leader at the top of the circle, and then adjust by
        // a residual amount depending on what the other two are doing.
        var fraction: Double
        if ranks[0] == 1 {
            fraction = residual(rank1: ranks[1], rank2: ranks[2])
        } else if ranks[1] == 1 {
            fraction = -1 + residual(rank1: ranks[2], rank2: ranks[0])
        } else {
            fraction = 1 + residual(rank1: ranks[0], rank2: ranks[1])
        }

        // Convert the fraction to an angle in radians.
        return fraction * 2.0 * Double.pi / 3.0
    }

    /// Gets the residual fraction based on what the other two ranks are doing.
    private func residual(rank1: Int, rank2: Int) -> Double {
        if rank1 == 1 {
            return -0.5
        } else if rank2 == 1 {
            return 0.5
        } else if rank1 < rank2 {
            return -0.25
        } else if rank1 > rank2 {
            return 0.25
        } else {
            return 0
        }
    }
}

/// A key that the layout uses to read the rank for a subview.
private struct Rank: LayoutValueKey {
    static let defaultValue: Int = 1
}

extension View {
    /// Sets the rank layout value on a view.
    func rank(_ value: Int) -> some View {
        layoutValue(key: Rank.self, value: value)
    }
}
