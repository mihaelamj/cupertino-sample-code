/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
SIMD utility functions.
*/

import simd

extension SIMD3 where Scalar == Float {
    
    /// Returns `true` if this point is visible in the scene.
    /// - Parameter matrix: The view projection matrix.
    func seenBy(matrix: simd_float4x4) -> Bool {
        var projected = matrix * SIMD4<Float>(self, 1)
        projected /= projected.w
        return (-1...1).contains(projected.x) && (-1...1).contains(projected.y)
    }
}

extension SIMD4 {
    /// The x, y, and z components of this vector that the system returns as a three-component vector.
    var xyz: SIMD3<Scalar> { .init(x: x, y: y, z: z) }
}
