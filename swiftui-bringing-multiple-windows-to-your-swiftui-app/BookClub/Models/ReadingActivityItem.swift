/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A reading activity data model representing a user's reading progress entry
 on macOS.
*/

import Foundation

struct ReadingActivityItem {
    var book: Book
    var entry: ReadingProgress.Entry
}

extension ReadingActivityItem: Comparable {
    static func <(lhs: ReadingActivityItem, rhs: ReadingActivityItem) -> Bool {
        if lhs.entry.date != rhs.entry.date {
            return lhs.entry.date < rhs.entry.date
        } else {
            return lhs.book.title < rhs.book.title
        }
    }
}

extension ReadingActivityItem: Equatable {
    static func ==(lhs: ReadingActivityItem, rhs: ReadingActivityItem) -> Bool {
        lhs.book.id == rhs.book.id && lhs.entry == rhs.entry
    }
}

extension ReadingActivityItem: Identifiable {
    struct ID: Hashable {
        var bookId: Book.ID
        var entryId: ReadingProgress.Entry.ID
    }
    
    var id: ID {
        ID(bookId: book.id, entryId: entry.id)
    }
}

extension ReadingActivityItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(book)
        hasher.combine(entry)
        hasher.combine(id)
    }
}
