/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions.
*/
import simd
import GameController

extension SIMD4 {
    var xyz: SIMD3<Scalar> {
        return self[SIMD3(0, 1, 2)]
    }
}

extension simd_float4x4 {
    var rotationMatrix: simd_float3x3 {
        simd_float3x3(columns.0.xyz, columns.1.xyz, columns.2.xyz)
    }
}

extension GCController {
    class func spatialControllers() -> [GCController] {
        GCController.controllers().filter { $0.productCategory == GCProductCategorySpatialController }
    }
}

extension SIMD3<Float> {
    /// Get a vector pointing in the same direction with length one (unit vector).
    func normalized() -> Self {
        return self / length(self)
    }
    
    // Get a rotation matrix with a y-axis that is this vector.
    func rotationMatrixAlignedOnYAxis(scaledTo scale: Float = 1.0) -> simd_float4x4 {
        // Create three orthogonal axes that define the rotation of the matrix,
        // where the y-axis is this vector (normalized).
        let normalizedY = self.normalized()
        var xAxis: SIMD3<Float> = [normalizedY.y, 0 - normalizedY.x, 0]
        var yAxis: SIMD3<Float> = normalizedY
        var zAxis: SIMD3<Float> = cross(xAxis, yAxis)
        
        // Apply the given uniform scale factor to all axes.
        xAxis *= scale
        yAxis *= scale
        zAxis *= scale
        
        // Output as a full 4x4 transform that you can use directly on entities.
        return simd_float4x4([xAxis.x, xAxis.y, xAxis.z, 0],
                             [yAxis.x, yAxis.y, yAxis.z, 0],
                             [zAxis.x, zAxis.y, zAxis.z, 0],
                             [0, 0, 0, 1])
    }
}
