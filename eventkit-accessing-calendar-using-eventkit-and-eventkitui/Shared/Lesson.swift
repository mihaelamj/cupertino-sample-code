/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The lesson model.
*/

import SwiftUI
import EventKit

/// Provides information about a lesson.
struct Lesson: Hashable, Identifiable, Codable {
    var id: String { name }
    
    /// Specifies whether the lesson is a recurring event or a single event.
    var type: LessonType
    var name: String
    
    /// Specifies the days on which the lesson occur.
    var days: [LessonDay]
    
    /// Specifies the time at which the lesson starts.
    var startAt: Int
    
    /// Specifies the lesson recurrence frequency.
    var repeats: LessonRecurrence?
    
    /// Specifies the lesson recurrence interval.
    var interval: Int?
    
    /// Specifies how often the lesson occurs.
    var occurrenceCount: Int?
    
    init(type: LessonType, name: String, days: [LessonDay], startAt: Int, repeats: LessonRecurrence? = nil, interval: Int? = nil,
         occurrenceCount: Int? = nil) {
        self.type = type
        self.name = name
        self.days = days
        self.startAt = startAt
        self.repeats = repeats
        self.interval = interval
        self.occurrenceCount = occurrenceCount
    }
}

extension Lesson {
    var title: String {
        return "Swim " + name
    }
    
    var titleAndBook: String {
        return "Book \(title)"
    }
    
    var titleAndStartAt: String {
        return "Book \(self.title) starting at \(self.startAtDate.timeAsText)"
    }
}
    
extension Lesson: Equatable {
    static func ==(lhs: Lesson, rhs: Lesson) -> Bool {
        lhs.id == rhs.id
    }
}

extension Lesson {
    static var dropinLessonMock: Lesson {
        Lesson(type: .single, name: "205", days: [.monday], startAt: 43_200)
    }
    
    static var repeatingLessonMock: Lesson {
        Lesson(type: .recurring, name: "105", days: [.friday], startAt: 39_900, repeats: .weekly, interval: 1, occurrenceCount: 8)
    }
}
