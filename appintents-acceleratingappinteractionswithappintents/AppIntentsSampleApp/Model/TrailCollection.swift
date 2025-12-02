/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data type representing the properties the app displays for a trail collection.
*/

import AppIntents
import Foundation

/// Represents a group of trails, such as Favorites, or those located in the same geographic region.
struct TrailCollection: Identifiable, Sendable {
    
    enum CollectionType: Int, Hashable, Codable, Sendable {
        case favorites = 0
        case browseTrails = 1
        case nearMe = 2
        case featured = 3
    }
    
    /// The collection's stable identifier.
    let id: Int
    
    /// What the collection represents, for UI purposes.
    let collectionType: CollectionType
    
    /// The name of the collection to display in the UI.
    @Property var name: String
    
    /// A symbol to use with the collection in the UI.
    let symbolName: String
    
    /// The trail IDs that belong to this collection.
    let members: [Trail.ID]
    
    init(id: Int, collectionType: CollectionType, name: String, symbolName: String, members: [Trail.ID]) {
        self.id = id
        self.collectionType = collectionType
        self.symbolName = symbolName
        self.members = members
        self.name = name
    }
}

/// This structure conforms to `AppEntity`, so this type is available to people and to the system through App Intents.
extension TrailCollection: AppEntity {
    
    /// Provide the system with the interface required to query `TrailCollection` structures.
    static let defaultQuery = FeaturedCollectionEntityQuery()
    
    /**
     A localized name representing this entity as a concept people are familiar with in the app, including
     localized variations based on the plural rules the app defines in `AppIntents.stringsdict`, which the system references
     here through the `table` parameter. The system may display this value to people when they configure an intent.
     */
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(
            name: LocalizedStringResource("Featured Trail Collection", table: "AppIntents"),
            numericFormat: LocalizedStringResource("\(placeholder: .int) featured trail collections", table: "AppIntents")
        )
    }
    
    /// Information on how to display the entity to people.
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)",
                              image: DisplayRepresentation.Image(systemName: symbolName))
    }
}

extension TrailCollection: Decodable {
    
    private enum CodingKeys: CodingKey {
        case id
        case collectionType
        case name
        case symbolName
        case members
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(Int.self, forKey: .id)
        collectionType = try values.decode(CollectionType.self, forKey: .collectionType)
        symbolName = try values.decode(String.self, forKey: .symbolName)
        members = try values.decode([Int].self, forKey: .members)
        name = try values.decode(String.self, forKey: .name)
    }
}

extension TrailCollection: Hashable {
    static func == (lhs: TrailCollection, rhs: TrailCollection) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
