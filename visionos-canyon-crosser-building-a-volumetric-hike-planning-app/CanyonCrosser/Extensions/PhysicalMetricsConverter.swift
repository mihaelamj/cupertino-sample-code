/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions on `PhysicalMetricsConverter`.
*/

import SwiftUI
import RealityKit

extension PhysicalMetricsConverter {
    /// Returns a `BoundingBox` in the specified unit.
    /// - Parameters:
    ///   - edges: The edges of the box.
    ///   - unit: The unit to convert to.
    func convert(edges: EdgeInsets3D, to unit: UnitLength) -> BoundingBox {
        BoundingBox(
            min: SIMD3<Float>(
                convert(Float(edges.leading), to: unit),
                convert(Float(edges.bottom), to: unit),
                convert(Float(edges.back), to: unit)
            ),
            max: SIMD3<Float>(
                convert(Float(edges.trailing), to: unit),
                convert(Float(edges.top), to: unit),
                convert(Float(edges.front), to: unit)
            )
        )
    }

    /// Returns a `BoundingBox` in meters.
    /// - Parameter bounds: The bounding box in the specified unit.
    func convertToMeters(bounds: Rect3D) -> BoundingBox {
        BoundingBox(
            min: SIMD3<Float>(
                convert(Float(bounds.min.x), to: .meters),
                convert(Float(bounds.min.y), to: .meters),
                convert(Float(bounds.min.z), to: .meters)
            ),
            max: SIMD3<Float>(
                convert(Float(bounds.max.x), to: .meters),
                convert(Float(bounds.max.y), to: .meters),
                convert(Float(bounds.max.z), to: .meters)
            )
        )
    }
}
