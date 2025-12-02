/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions on `Date`.
*/

import SwiftUI

extension Date {
    /// Rounds the date to the nearest 15 minute chunk.
    func roundTo15Mins() -> Date {
        let fifteenMinuteIncrement = (self.timeIntervalSinceReferenceDate / .fifteenMinutesInSeconds).rounded(.toNearestOrEven)

        return Date(timeIntervalSinceReferenceDate: fifteenMinuteIncrement * .fifteenMinutesInSeconds)
    }
    
    /// Rounds the date to the nearest hour.
    func roundHourDown() -> Date {
        Date(timeIntervalSinceReferenceDate: (self.timeIntervalSinceReferenceDate / .oneHourInSeconds).rounded(.down) * .oneHourInSeconds)
    }
    
    /// Returns the hour component of the date.
    func hour() -> Int {
        Calendar.current.dateComponents([.hour], from: self).hour ?? 0
    }
    
    /// Returns the minute component of the date.
    func minutes() -> Int {
        Calendar.current.dateComponents([.minute], from: self).minute ?? 0
    }
}
