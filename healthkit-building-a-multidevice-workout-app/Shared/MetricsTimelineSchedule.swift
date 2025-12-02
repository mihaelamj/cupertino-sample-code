/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides a custom timeline schedule for updating the metrics.
*/

import SwiftUI

struct MetricsTimelineSchedule: TimelineSchedule {
    let startDate: Date
    let isPaused: Bool

    init(from startDate: Date, isPaused: Bool) {
        self.startDate = startDate
        self.isPaused = isPaused
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        let newMode = (mode == .lowFrequency ? 1.0 : 1.0 / 30.0)
        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate, by: newMode).entries(from: startDate, mode: mode)
        
        return AnyIterator<Date> {
            return isPaused ? nil : baseSchedule.next()
        }
    }
}
