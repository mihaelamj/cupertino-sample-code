/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The labels and weather for the timeline in the toolbar.
*/

import SwiftUI

struct TimelineLabel: Identifiable, Hashable {
    let id = UUID()
    let time: Date
    let weather: Weather
}

struct Weather: Identifiable, Hashable {
    let id = UUID()
    let temperature: Int
    var color: Color {
        if self.temperature >= 84 {
            return Color.eightyFiveDegrees
        } else if self.temperature >= 80 {
            return Color.eightyDegrees
        } else if self.temperature >= 70 {
            return Color.seventyDegrees
        } else if self.temperature >= 60 {
            return Color.sixtyDegrees
        } else if self.temperature >= 50 {
            return Color.fiftyDegrees
        }
        return Color.fortyDegrees
    }
}
