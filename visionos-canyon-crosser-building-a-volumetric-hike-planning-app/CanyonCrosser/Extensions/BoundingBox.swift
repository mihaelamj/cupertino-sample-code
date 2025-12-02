/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions on `BoundingBox`.
*/

import SwiftUI
import RealityKit

extension BoundingBox {
    /// Returns a new `BoundingBox`, expanded by the given margins.
    /// - Parameter margins: The margins to add to the bounding box.
    func adding(margins: BoundingBox) -> BoundingBox {
        BoundingBox(min: self.min - margins.min, max: self.max + margins.max)
    }
}
