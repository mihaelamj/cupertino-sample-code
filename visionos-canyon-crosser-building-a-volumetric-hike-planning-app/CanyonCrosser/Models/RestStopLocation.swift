/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Describes the multiple locations a rest stop can have on a hike.
*/

public struct RestStopLocation: Hashable, Sendable {
    /// The time at which you are pausing at the rest stop, either when ascending or descending.
    var restStopDirection: RestStopDirection
    /// The percentage of the trail that has been covered before visiting the rest stop.
    var trailPercentage: Float

    init(restStopDirection: RestStopDirection, trailPercentage: Float) {
        self.restStopDirection = restStopDirection
        self.trailPercentage = trailPercentage
    }
    
    /// An enumeration that indicates whether the hiker is ascending or descending the trail when pausing at a rest stop.
    enum RestStopDirection: String {
        /// Rest taken while ascending the trail.
        case ascent = "Ascent Rest"
        /// Rest taken while descending the trail.
        case descent = "Descent Rest"
        /// Rest taken when there is only one option, such as at the base of the trail.
        case base = "Rest Stop"
    }
}
