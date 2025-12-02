/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A reading activity data model representing a user's reading progress
 entries on macOS.
*/

import Combine

#if os(macOS)
class ReadingActivity: ObservableObject {
    let items: [CurrentlyReading]
    
    init(_ items: [CurrentlyReading]) {
        self.items = items
    }
    
    var entries: AnyPublisher<[ReadingActivityItem], Never> {
        items.publisher.flatMap { item in
            item.progress.entries.publisher.map { entry in
                ReadingActivityItem(book: item.book, entry: entry)
            }
        }
        .collect()
        .eraseToAnyPublisher()
    }
}
#endif
