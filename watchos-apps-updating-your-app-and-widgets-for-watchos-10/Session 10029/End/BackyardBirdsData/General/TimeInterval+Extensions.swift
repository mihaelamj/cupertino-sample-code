/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to TimeInterval.
*/

import Foundation

public extension TimeInterval {
    /// Creates an imaginary time of day for a backyard.
    ///
    /// - Warning: This code is solely intended for use with Backyard Birds' imaginary "time of day" concept for each backyard.
    /// When dealing with real-world time, use `Date` and `Calendar`.
    init(days: Double = 0, hours: Double = 0, minutes: Double = 0, seconds: Double = 0) {
        self = (24 * 60 * 60 * days) + (60 * 60 * hours) + (60 * minutes) + seconds
    }
}
