/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The recurence details of a lesson.
*/

import EventKit

enum LessonRecurrence: Int, Hashable, CaseIterable, Identifiable, Codable {
    var id: Int { rawValue }
    
    case weekly = 1
    case monthly = 2
    
    var frequency: EKRecurrenceFrequency {
        switch self {
        case .weekly: return .weekly
        case .monthly: return .monthly
        }
    }
}

extension Lesson {
    /// Formats the number of recurring lesson occurences.
    var numberOfRecurringLessons: String {
        guard let lessonCount = occurrenceCount else {
            fatalError()
        }
        return "No. of lessons: \(lessonCount)"
    }
    
    /// The amount of occurences of a recurring lesson.
    var recurrenceEnd: EKRecurrenceEnd {
        guard let occurrenceCount = occurrenceCount else { fatalError() }
        return EKRecurrenceEnd(occurrenceCount: occurrenceCount)
    }
    
    /// Specifies when a recurring lesson ends.
    var recurenceRule: EKRecurrenceRule {
        let recurrenceDayOfWeek = days.map({ (item: LessonDay) in item.dayOfWeek })
        guard let repeats = repeats, let interval = interval else { fatalError() }
        
        return EKRecurrenceRule(recurrenceWith: repeats.frequency,
                                interval: interval,
                                daysOfTheWeek: recurrenceDayOfWeek,
                                daysOfTheMonth: nil,
                                monthsOfTheYear: nil,
                                weeksOfTheYear: nil,
                                daysOfTheYear: nil,
                                setPositions: nil,
                                end: recurrenceEnd)
    }
}
