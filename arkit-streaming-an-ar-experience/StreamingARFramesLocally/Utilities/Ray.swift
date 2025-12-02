/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of a ray in a form that you can easily serialize for sending over a network.
*/
struct Ray: Codable {
    let direction: SIMD3<Float>
    let origin: SIMD3<Float>
}
