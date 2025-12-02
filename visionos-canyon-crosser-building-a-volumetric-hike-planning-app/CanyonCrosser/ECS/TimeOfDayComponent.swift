/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component to animate shadows and sunlight to the set time of day.
*/

import RealityKit

struct TimeOfDayComponent: Component {
    // The time of day, as a percentage of the 24-hour clock.
    var timeOfDay: Float = 0.0

    // The desired time of day, used to change the time of day.
    var targetTimeOfDay: Float = 0.0

    // The amount of time of day change to apply on each frame.
    var timeOfDayChangePerFrame: Float = 1.0
}
