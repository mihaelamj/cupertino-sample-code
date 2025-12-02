/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A navigation model used to persist and restore navigation state.
*/

import Combine
import SwiftUI

class NavigationModel: Codable, ObservableObject {
    enum CodingKeys: String, CodingKey {
        case columnVisibility
        case selectedCategory
        case selectedBookIds
    }
    
    @Published var columnVisibility: NavigationSplitViewVisibility
    @Published var selectedCategory: Category?
    @Published var selectedBookIds: Set<Book.ID> = []
    @Published var jsonData: Data?
    
    private lazy var encoder = JSONEncoder()
    
    init(
        columnVisibility: NavigationSplitViewVisibility = .all,
        selectedCategory: Category? = .default,
        selectedBookIds: Set<Book.ID> = []
    ) {
        self.columnVisibility = columnVisibility
        self.selectedCategory = selectedCategory
        self.selectedBookIds = selectedBookIds
        
        Publishers.Merge3(
            $columnVisibility.map { _ in },
            $selectedCategory.map { _ in },
            $selectedBookIds.map { _ in }
        )
        .compactMap { [weak self] in
            guard let self = self else { return nil }
            return try? self.encoder.encode(self)
        }
        .assign(to: &$jsonData)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        columnVisibility = try container.decode(
            NavigationSplitViewVisibility.self, forKey: .columnVisibility)
        selectedCategory = try container.decodeIfPresent(
            Category.self, forKey: .selectedCategory)
        selectedBookIds = try container.decodeIfPresent(
            Set<Book.ID>.self, forKey: .selectedBookIds) ?? []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(columnVisibility, forKey: .columnVisibility)
        try container.encodeIfPresent(selectedCategory, forKey: .selectedCategory)
        try container.encodeIfPresent(selectedBookIds, forKey: .selectedBookIds)
    }
}

extension NavigationModel: Equatable {
    static func ==(lhs: NavigationModel, rhs: NavigationModel) -> Bool {
        if ObjectIdentifier(lhs) == ObjectIdentifier(rhs) {
            return true
        }
        return lhs.columnVisibility == rhs.columnVisibility &&
        lhs.selectedCategory == rhs.selectedCategory &&
        lhs.selectedBookIds == rhs.selectedBookIds
    }
}

extension Optional where Wrapped == Category {
    fileprivate static var `default`: Category? {
        #if os(macOS)
        .all
        #else
        nil
        #endif
    }
}
