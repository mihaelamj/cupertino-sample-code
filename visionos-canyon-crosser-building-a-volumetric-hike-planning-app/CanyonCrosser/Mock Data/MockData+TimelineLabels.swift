/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Labels for the hike timeline.
*/

import Foundation

extension MockData {
    static let timelineLabels: [TimelineLabel] = {
        (0...23).map { hour in
            TimelineLabel(
                time: Calendar.current.startOfDay(for: Date()).addingTimeInterval(.oneHourInSeconds * Double(hour)),
                weather: MockData.weather[hour]
            )
        }
    }()
}
