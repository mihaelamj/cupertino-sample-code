/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The date details of a lesson.
*/

import EventKit

enum LessonDay: Int, Hashable, CaseIterable, Identifiable, Codable {
    var id: Int { rawValue }
    
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var name: String {
        switch self {
            case .sunday: return "Sunday"
            case .monday: return  "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
        }
    }

    var weekDay: EKWeekday {
        switch self {
            case .monday: return .monday
            case .tuesday: return .tuesday
            case .wednesday: return .wednesday
            case .thursday: return .thursday
            case .friday: return .friday
            case .sunday: return .sunday
            case .saturday: return .saturday
        }
    }
    
    var dayOfWeek: EKRecurrenceDayOfWeek {
        return EKRecurrenceDayOfWeek(self.weekDay)
    }
}

extension Lesson {
    var startAtDate: Date {
        return TimeInterval(startAt).toTodayDate
    }
    
    var endAtDate: Date {
        return startAtDate.thirtyMinutesLater
    }
    
    var fromStartAtToEndAtAsText: String {
        return "\(startAtDate.timeAsText) to \(endAtDate.timeAsText)"
    }
    
    var daysAsText: String {
        return days.map({ (day: LessonDay) in day.name }).joined(separator: " and ")
    }
}

extension Lesson {
    /// Create the date at which a drop-in lesson starts.
    func lessonWithDate(date: Date) -> Date {
        let result = TimeInterval(startAt)
        return Calendar.current.date(bySettingHour: result.hour, minute: result.minute, second: 0, of: date) ?? date
    }
    
    /// Fetch the next date that occurs after the currently selected day.
    func nextDateMatchingScheduledLessons(date: Date) -> Date {
        let indexSet = IndexSet(self.days.map({ (item: LessonDay) in item.dayOfWeek.dayOfTheWeek.rawValue }))
        let result = date.fetchNextDateFromDays(indexSet)
        
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .month], from: result)
        components.hour = TimeInterval(startAt).hour
        components.minute = TimeInterval(startAt).minute
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// Create the date at which a lesson begins.
    func buildStartDate(date: Date) -> Date {
        switch type {
        case .single:
            return lessonWithDate(date: date)
        case .recurring:
            return nextDateMatchingScheduledLessons(date: date)
        }
    }
    
    /// Create an event with the lesson details. Use the user's default calendar if the specified calendar doesn't exist.
    func eventWithDate(_ date: Date, store: EKEventStore, calendar: EKCalendar? = nil) -> EKEvent {
        let startDate = buildStartDate(date: date)
        let endDate = startDate.thirtyMinutesLater
        
        let newEvent = EKEvent(lesson: self,
                               eventStore: store,
                               calendar: calendar ?? store.defaultCalendarForNewEvents,
                               startDate: startDate,
                               endDate: endDate)
        
        return newEvent
    }
}
