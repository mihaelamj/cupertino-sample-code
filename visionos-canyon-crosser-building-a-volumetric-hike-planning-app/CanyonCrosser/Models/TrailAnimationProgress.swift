/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure to represent the progress along an out and back hiking trail, with optional rest stops.
*/

struct TrailAnimationProgress: Sendable {
    let progress: Float
    let location: RestStopLocation?
    let returningBack: Bool

    static let zero = TrailAnimationProgress(progress: 0.0, location: nil, returningBack: false)
}
