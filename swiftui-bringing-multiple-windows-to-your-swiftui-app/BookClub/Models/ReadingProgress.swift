/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A reading progress data model used to track progress,
 and an entry data model used for input data.
*/

import Foundation

struct ReadingProgress {
    var calendar: Calendar = .current
    private(set) var progress: Double = 0
    private(set) var entriesByDate: [EntriesByDate] = []
    
    var entries: [Entry] {
        entriesByDate.flatMap(\.entries)
    }
    
    mutating func mark(
        _ progress: Double,
        date: Date = Date(),
        note: String? = nil
    ) {
        let entry = Entry(progress: progress, date: date, note: note)
        addEntry(entry)
    }

    private mutating func addEntry(_ entry: Entry) {
        let dateComponents = entry.date.components(from: calendar)
        let existingEntryWithDateComponent = entriesByDate.first(where: {
            $0.dateComponents == dateComponents
        })
        
        if let existingEntryByDate = existingEntryWithDateComponent {
            existingEntryByDate.entries.append(entry)
        } else {
            let newEntryByDate = EntriesByDate(entry: entry, calendar: calendar)
            entriesByDate.append(newEntryByDate)
        }
        
        progress = entry.progress
    }
}

extension ReadingProgress {
    class EntriesByDate: Hashable {
        let date: Date
        var entries: [Entry]
        let dateComponents: DateComponents
        
        init(date: Date, entries: [Entry], calendar: Calendar) {
            self.date = date
            self.entries = entries
            dateComponents = date.components(from: calendar)
        }
        
        convenience init(entry: Entry, calendar: Calendar) {
            self.init(date: entry.date, entries: [entry], calendar: calendar)
        }
        
        func contains(_ entry: Entry) -> Bool {
            entries.contains(entry)
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(date)
            hasher.combine(entries)
            hasher.combine(dateComponents)
        }
        
        static func ==(lhs: EntriesByDate, rhs: EntriesByDate) -> Bool {
            if ObjectIdentifier(lhs) == ObjectIdentifier(rhs) {
                return true
            }
            return lhs.dateComponents == rhs.dateComponents &&
            lhs.entries == rhs.entries
        }
    }

    struct Entry: Identifiable, Comparable, Hashable {
        let id = UUID()
        let progress: Double
        let date: Date
        let calendar: Calendar = .current
        let note: String?
        
        var dateComponents: DateComponents {
            date.components(from: calendar)
        }

        static func <(lhs: Entry, rhs: Entry) -> Bool {
            lhs.date < rhs.date
        }
    }
}
