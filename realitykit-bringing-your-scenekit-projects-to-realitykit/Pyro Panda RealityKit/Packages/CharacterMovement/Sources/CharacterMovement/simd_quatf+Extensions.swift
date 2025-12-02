/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper computed value for flattening quaternions.
*/

import simd

extension simd_quatf {
    var flattened: simd_quatf {
        let forward = simd_normalize(simd_act(self, [0, 0, 1]))
        var flatForward = forward
        flatForward.y = 0
        flatForward = simd_normalize(flatForward)

        return simd_quatf(from: [0, 0, 1], to: flatForward)
    }
}
