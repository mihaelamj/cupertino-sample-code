/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extends the event class.
*/

import EventKit

extension EKEvent {
    /// Creates a nonfloating event that uses the specified lesson, event store, calendar, start date, and end date.
    convenience init(lesson: Lesson, eventStore store: EKEventStore, calendar: EKCalendar?, startDate: Date, endDate: Date) {
        self.init(eventStore: store)
        self.title = lesson.title
        self.calendar = calendar
        self.startDate = startDate
        self.endDate = endDate
    
        // A floating event is one that isn't associated with a specific time zone. Set `timeZone` to nil if you wish to have a floating event.
        self.timeZone = TimeZone.current
        
        if lesson.type == .recurring {
            self.addRecurrenceRule(lesson.recurenceRule)
        }
    }
}
