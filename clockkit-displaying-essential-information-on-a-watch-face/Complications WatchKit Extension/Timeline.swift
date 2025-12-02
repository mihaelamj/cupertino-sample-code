/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The timeline used as the data source of the complications.
*/

import Foundation

// Date formatter for processing the start and end time in the timeline.
// Provide this extension so that the whole sample uses the same style formatter.
//
extension DateFormatter {
    class func shortTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// The timeline in this sample is "every day's timeline", meaning the events repeat every day.
// So the following general terms have specific meaning in the sample:
// - time: a DateComponents containing hour, minute, and second.
// - date: a date whose year:month:day components are valid.
// - datetime: a date whose components are all valid, specifying the time of an event on a certain date.
//
struct Event {
    let name: String
    let desc: String
    let startTime: DateComponents
    let endTime: DateComponents

    // The concrete event date used for past and future events
    // Only year:month:day components are meaningful.
    var date: Date?
    
    private func dateTime(time: DateComponents, date: Date) -> Date {
        guard let hour = time.hour, let minute = time.minute, let second = time.second else {
            fatalError("Failed to retrieve time components from \(time).")
        }
        guard let newDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: second, of: date) else {
            fatalError("Failed to create a date based on \(time) and \(date).")
        }
        return newDate
    }
        
    func startDateTime(onDate: Date) -> Date {
        return dateTime(time: startTime, date: onDate)
    }
    
    func endDateTime(onDate: Date) -> Date {
        return dateTime(time: endTime, date: onDate)
    }
}

struct Timeline {
    var events = [Event]()
    
    // Create a demo timeline.
    // The demo data: 24 event from event0 to event23, every event lasts 59m:59s.
    //
    static func demoTimeline() -> Timeline {
        var startComponents = DateComponents(hour: 0, minute: 0, second: 0)
        var endComponents = DateComponents(hour: 0, minute: 59, second: 59)
        var timeLine = Timeline()

        for hour in 0..<24 {
            startComponents.hour = hour
            endComponents.hour = hour
            let event = Event(name: String(format: "E%02d", hour),
                              desc: String(format: "EVENT%02d", hour),
                              startTime: startComponents, endTime: endComponents)
            timeLine.events.append(event)
        }
        return timeLine
    }
    
    // Retrieve the event at the specified data time.
    // Return nil if nothing matched.
    //
    func event(at dateTime: Date) -> Event? {
        let matched = events.filter {
            dateTime >= $0.startDateTime(onDate: dateTime) && dateTime <= $0.endDateTime(onDate: dateTime)
        }
        var event = matched.first // event can be nil if no matched event at datTime.
        event?.date = dateTime
        return event
    }
    
    // Return the events for next day for the system to cache and automatically progress through.
    // next day: the next 24 hours from dateTime
    //
    func nextDayEvents(after dateTime: Date) -> [Event] {
        let targetEventNumber = events.count

        // Get the future events of the date after the specified dateTime.
        var futureEvents = events.filter { dateTime < $0.startDateTime(onDate: dateTime) }
        futureEvents.indices.forEach { futureEvents[$0].date = dateTime }

        if futureEvents.count >= targetEventNumber {
            return futureEvents
        }
        
        // Get the next date using current calendar and return all events of the date.
        let calendar = Calendar.current
        guard let nextDate = calendar.nextDate(after: dateTime,
                                               matching: DateComponents(hour: 0, minute: 0, second: 0),
                                               matchingPolicy: .nextTime,
                                               repeatedTimePolicy: .first,
                                               direction: .forward)
            else {
                fatalError("Failed to find next date for dateTime: \(dateTime)!")
        }
        
        // Add the events of next date until the total future events reach the target number.
        for var event in events where futureEvents.count <= targetEventNumber {
            event.date = nextDate
            futureEvents.append(event)
        }
        
        return futureEvents
    }

    // Retrieve the end date time of the timeline.
    //
    func endDateTime(after dateTime: Date) -> Date? {
        let events = nextDayEvents(after: dateTime)
        return events.last?.endDateTime(onDate: dateTime)
    }
}
