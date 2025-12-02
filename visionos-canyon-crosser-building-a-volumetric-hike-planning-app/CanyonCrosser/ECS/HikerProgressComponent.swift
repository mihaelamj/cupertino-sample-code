/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component that stores the position of the hiker.
*/

import RealityKit
import Foundation

struct HikerProgressComponent: Component {
    /// The total progress of a hike from 0.0 to 1.0.
    var hikeProgress: Float = 0.0

    typealias Animation = (toValue: Float, fromValue: Float, elapsedTime: TimeInterval)

    var animation: Animation? = nil
}
