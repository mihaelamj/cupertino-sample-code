/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The event information when a backyard has a visitor.
*/

import Foundation

final class BackyardVisitorEvent {
    let id: UUID
    var backyard: Backyard
    var bird: Bird
    var startDate: Date
    var duration: TimeInterval

    var endDate: Date {
        startDate.addingTimeInterval(duration)
    }

    var dateRange: Range<Date> {
        startDate ..< endDate
    }

    init(id: UUID = UUID(), backyard: Backyard, bird: Bird, startDate: Date, duration: TimeInterval) {
        self.id = id
        self.bird = bird
        self.backyard = backyard
        self.startDate = startDate
        self.duration = duration
    }
}

