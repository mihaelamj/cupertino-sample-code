/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Default times.
*/

import Foundation

/// These are dynamically set when the hike date changes, but these are necessary for a default.
extension MockData {
    // Get the start of the day to calculate the departure and arrival times.
    static private let startOfDay = Calendar.current.startOfDay(for: Date())

    // The time to depart, set to 7 a.m.
    static let departureTime = startOfDay.addingTimeInterval(.oneHourInSeconds * 7)
}
