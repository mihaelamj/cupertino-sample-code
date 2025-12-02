/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities for making geometric calculations on CGPoint and CGrect objects.
*/

import CoreGraphics

/// Calculates the intersection over union (IOU) of two rectangles
///
/// This can be thought of as the overlap between two rectangles
/// - parameters:
///     - firstRect: The first rectangle
///     - secondRect: The second rectangle
/// - returns: The intersection over union of the two rectangles
func intersectionOverUnion(_ firstRect: CGRect, _ secondRect: CGRect) -> CGFloat {
    guard !firstRect.isEmpty, !secondRect.isEmpty else {
        return 0
    }

    let intersection = firstRect.intersection(secondRect)
    return intersection.area / (firstRect.area + secondRect.area - intersection.area)
}

/// The reciprocal extension on CGRect that can tell us if it contains a given point
private extension CGRect {

    /// The area of a rectangle
    var area: CGFloat {
        return width * height
    }
}

