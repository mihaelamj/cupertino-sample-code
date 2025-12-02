/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents a card.
*/

import Foundation
import SwiftData

@Model
final class Card {
    var front: String
    var back: String
    var creationDate: Date

    init(front: String, back: String, creationDate: Date = .now) {
        self.front = front
        self.back = back
        self.creationDate = creationDate
    }
}

extension Card: Hashable {
    static func == (lhs: Card, rhs: Card) -> Bool {
        lhs.front == rhs.front &&
        lhs.back == rhs.back &&
        lhs.creationDate == rhs.creationDate
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(front)
        hasher.combine(back)
        hasher.combine(creationDate)
    }
}

// MARK: Migration

struct FlashCardsMigrationPlan: SchemaMigrationPlan {
    static let schemas: [VersionedSchema.Type] = [FlashCardsVersionedSchema.self]
    static let stages: [MigrationStage] = []
}

struct FlashCardsVersionedSchema: VersionedSchema {
    static let models: [any PersistentModel.Type] = [Card.self]
    static let versionIdentifier: Schema.Version = .init(1, 0, 0)
}
