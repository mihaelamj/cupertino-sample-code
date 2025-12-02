/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A reading list data model which generates mocked books for the sample app.
*/

import Combine
import Foundation

class ReadingListModel: ObservableObject {
    @Published var items: [CurrentlyReading]
    let categories: [Category]
    
    #if os(macOS)
    let activity: ReadingActivity
    #endif
    
    var favorites: [CurrentlyReading] {
        items.filter { $0.isFavorited }
    }
    
    var currentlyReading: [CurrentlyReading] {
        items.filter { $0.hasProgress }
    }
    
    var wishlist: [CurrentlyReading] {
        items.filter { $0.isWishlisted }
    }
    
    init(
        items: [CurrentlyReading] = .mocks,
        categories: [Category] = .mocks
    ) {
        self.items = items
        self.categories = categories
        #if os(macOS)
        self.activity = ReadingActivity(items)
        #endif
    }
    
    var objectWillChange: AnyPublisher<Void, Never> {
        $items
            .flatMap(\.publisher)
            .flatMap(\.objectWillChange)
            .eraseToAnyPublisher()
    }
    
    subscript(book id: Book.ID) -> CurrentlyReading? {
        items.first { $0.book.id == id }
    }
    
    subscript(books ids: [Book.ID]) -> [CurrentlyReading] {
        items.filter { ids.contains($0.id) }
    }

    subscript(category category: Category) -> [CurrentlyReading] {
        switch category {
        case .all:
            return items
        case .favorites:
            return favorites
        case .currentlyReading:
            return currentlyReading
        case .wishlist:
            return wishlist
        }
    }
    
    func items(
        for category: Category,
        matching query: String
    ) -> [CurrentlyReading] {
        let items = self[category: category]
        guard !query.isEmpty else { return items }
        return items.filter { $0.containsCaseInsensitive(query: query) }
    }
}
