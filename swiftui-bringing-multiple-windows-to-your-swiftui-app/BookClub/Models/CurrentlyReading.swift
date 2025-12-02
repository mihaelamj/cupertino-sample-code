/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A currently reading data model, which publishes changes to its subscribers.
*/

import SwiftUI

class CurrentlyReading: Identifiable, ObservableObject {
    let book: Book
    @Published var progress = ReadingProgress()
    @Published var isFavorited = false
    @Published var isFinished = false
    
    var id: Book.ID {
        book.id
    }

    init(book: Book) {
        self.book = book
    }
    
    var isWishlisted: Bool {
        !hasProgress
    }
    
    var hasProgress: Bool {
        currentProgress > 0
    }

    var currentProgress: Double {
        isFinished ? 1.0 : progress.progress
    }

    func markProgress(_ newProgress: Double, note: String? = nil) {
        progress.mark(newProgress, note: note)
    }

    func containsCaseInsensitive(query: String) -> Bool {
        guard !query.isEmpty else { return false }
        let content = [
            book.title,
            book.author,
            book.description
        ] + progress.entries.compactMap(\.note)
        
        let results = content.first(where: {
            $0.range(of: query, options: .caseInsensitive) != nil
        })
        return results != nil
    }
}

extension CurrentlyReading {
    static var mock: CurrentlyReading {
        MockFactory.currentlyReading[0]
    }
    
    static var mockFavorited: CurrentlyReading {
        let item = mock
        item.markProgress(0.5, note: "I love this!")
        item.isFavorited = true
        return item
    }
    
    static var mockWishlisted: CurrentlyReading {
        let item = mock
        item.markProgress(0, note: nil)
        item.isFavorited = false
        return item
    }
}

extension Collection where Element == CurrentlyReading {
    static var mocks: [CurrentlyReading] {
        MockFactory.currentlyReading
    }
}

extension Collection where Element == Category {
    static var mocks: [Category] {
        MockFactory.categories
    }
}

extension Color {
    fileprivate static func random<G: RandomNumberGenerator>(
        using generator: inout G
    ) -> Color {
        let hue = Double.random(in: 0...255, using: &generator) / 256
        let brightness = Double.random(in: 64...127, using: &generator) / 256
        return Color(
            hue: hue,
            saturation: 1,
            brightness: brightness,
            opacity: 1)
    }
}

private enum MockFactory {
    static let currentlyReading: [CurrentlyReading] = makeCurrentlyReading()
    
    static let categories = Category.allCases
    
    static func books() -> [Book] {
        var generator = SeededRandomNumberGenerator(seed: 6)
        return [
            book(
                title: "Great Expectations",
                author: "Charles Dickens",
                using: &generator),
            book(
                title: "Pride and Prejudice",
                author: "Jane Austen",
                using: &generator),
            book(
                title: "Little Women",
                author: "Louisa May Alcott",
                using: &generator),
            book(
                title: "Wuthering Heights",
                author: "Emily Brontë",
                using: &generator),
            book(
                title: "Moby Dick",
                author: "Herman Melville",
                using: &generator),
            book(
                title: "Anne of Green Gables",
                author: "L.M. Montgomery",
                coverName: "Anne of Gables",
                using: &generator),
            book(
                title: "The Adventures of Sherlock Holmes",
                author: "Arthur Conan Doyle",
                coverName: "Sherlock Holmes",
                using: &generator),
            book(
                title: "Dracula",
                author: "Bram Stroker",
                using: &generator),
            book(
                title: "Frankenstein",
                author: "Mary Shelley",
                using: &generator)
        ]
    }
    
    private static func book<G: RandomNumberGenerator>(
        title: String,
        author: String,
        coverName: String? = nil,
        using generator: inout G
    ) -> Book {
        Book(
            title: title,
            author: author,
            color: .random(using: &generator),
            coverName: coverName == nil ? title : coverName!,
            description: placeholderDescription)
    }
    
    private static let placeholderDescription =
        """
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. \
        Maecenas maximus viverra interdum. Ut interdum posuere magna, \
        id porttitor ligula vehicula a. In turpis est, imperdiet non ante non, \
        ultrices bibendum eros. Nam id lacinia tellus. Aliquam libero neque, \
        fringilla eget mi a, ornare molestie sapien. Aenean malesuada tellus \
        sit amet justo placerat, at egestas ligula pretium.
        """
    
    private static let placeholderNotes = [
            """
            "Donec hendrerit justo sit amet arcu bibendum fringilla. \
            Aenean scelerisque at orci vel dictum. \
            Nam semper viverra viverra.
            """,
            """
            Suspendisse elementum, tellus in malesuada hendrerit, \
            sapien augue semper dolor, ac accumsan turpis risus in sem.
            """,
            """
            Cras congue vel dui at semper. Etiam arcu ligula, \
            pharetra sed cursus vel, dictum eget lacus. \
            Nam lacinia maximus dolor, eget mattis dui fermentum sed.
            """,
            """
            Nam non purus id diam vulputate vestibulum vitae quis neque.
            """,
            """
            Sed ex felis, feugiat et felis sit amet, elementum euismod eros. \
            Quisque gravida lobortis lacus, eu gravida nisl rhoncus quis.
            """
    ]

    private static func makeCurrentlyReading() -> [CurrentlyReading] {
        var books = books().map(CurrentlyReading.init)
        let principalDate = Date(timeIntervalSince1970: 1_654_533_660)
        makeReadingProgress(for: &books, endDate: principalDate)
        makeFavorited(for: &books)
        makePrincipalBook(from: &books, startDate: principalDate)
        return books
    }
    
    private static func makeReadingProgress(
        for books: inout [CurrentlyReading],
        endDate: Date
    ) {
        let low = [0.1, 0.2, 0.3]
        let mid = [0.4, 0.5, 0.6]
        let high = [0.7, 0.8, 0.9]
        
        var generator = SeededRandomNumberGenerator(seed: 6)
        let progressBooks = books
            .dropFirst() // skip the principal book.
            .shuffled()
            .suffix(4) // randomly generate progress for (books 1-5)
        
        progressBooks.forEach { book in
            let dates = weekdays(endingOn: endDate).sorted()
            
            book.progress.mark(
                low.randomElement(using: &generator)!,
                date: dates[0...2].randomElement(using: &generator)!,
                note: placeholderNotes.randomElement(using: &generator)!)
            book.progress.mark(
                mid.randomElement(using: &generator)!,
                date: dates[3...4].randomElement(using: &generator)!,
                note: placeholderNotes.randomElement(using: &generator)!)
            book.progress.mark(
                high.randomElement(using: &generator)!,
                date: dates[5...6].randomElement(using: &generator)!,
                note: placeholderNotes.randomElement(using: &generator)!)
        }
    }
    
    private static func makeFavorited(for books: inout [CurrentlyReading]) {
        let favoritedBooks = books.filter { $0.hasProgress }
            .shuffled()
            .prefix(3)
        
        for book in favoritedBooks {
            book.isFavorited = true
        }
    }
    
    private static func makePrincipalBook(
        from books: inout [CurrentlyReading],
        startDate: Date
    ) {
        let principalBook = books[0]
        principalBook.progress.mark(
            0.1,
            date: startDate,
            note: "😶")
        
        principalBook.progress.mark(
            0.42,
            date: Date(timeIntervalSince1970: 1_654_553_520),
            note: """
Maybe I should be working on my WWDC talk \
instead of reading, but this book is so good.
""")
        
        principalBook.progress.mark(
            0.57,
            date: Date(timeIntervalSince1970: 1_654_566_660),
            note: "🤔")
    }
    
    private static func weekdays(
        endingOn endDate: Date,
        in calendar: Calendar = .current
    ) -> [Date] {
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        let weekdayRange = calendar.range(
            of: .weekday,
            in: .weekOfYear,
            for: startDate)!
        let dayOfWeek = calendar.component(.weekday, from: startDate) - 1
        let weekdays = weekdayRange.compactMap { weekday in
            calendar.date(
                byAdding: .day,
                value: weekday - dayOfWeek,
                to: startDate)
        }
        return weekdays
    }
    
    private static func randomDateInMonth() -> Date? {
        let date = Date()
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.year, .month, .day]
        var dateComponents = calendar.dateComponents(components, from: date)
        guard let days = calendar.range(of: .day, in: .month, for: date)
        else { return nil }
        
        let randomDay = days.randomElement()
        dateComponents.setValue(randomDay, for: .day)
        return calendar.date(from: dateComponents)
    }
}

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }

    func next() -> UInt64 {
        UInt64(drand48() * Double(UInt64.max))
    }
}
