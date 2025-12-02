/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App entity that represents a collection.
*/

import AppIntents

struct CollectionEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        return TypeDisplayRepresentation(
            name: LocalizedStringResource("Collection", table: "AppIntents", comment: "The type name for the Collection entity"),
            numericFormat: "\(placeholder: .int) collections"
        )
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(description)",
            image: .init(systemName: "square.stack.3d.down.right.fill")
        )
    }

    static let defaultQuery = CollectionEntityQuery()

    var id: Int

    @Property
    var name: String

    @Property
    var description: String

    @Property
    var landmarks: [LandmarkEntity]

    init(collection: Collection, modelData: ModelData) {
        self.id = collection.id
        self.name = collection.name
        self.description = collection.description
        self.landmarks = collection.landmarks.map {
            LandmarkEntity(landmark: $0, modelData: modelData)
        }
    }
}

@MainActor
struct CollectionEntityQuery: EntityStringQuery {
    @Dependency var modelData: ModelData

    func entities(for identifiers: [CollectionEntity.ID]) async throws -> [CollectionEntity] {
        var collections: [Collection] = []
        for collectionId in identifiers {
            if let collection = modelData.userCollections.first(where: { $0.id == collectionId }) {
                collections.append(collection)
            }
        }
        return collections.map {
            CollectionEntity(collection: $0, modelData: modelData)
        }
    }

    func entities(matching: String) async throws -> [CollectionEntity] {
        var collections: [Collection] = []
        for collection in modelData.userCollections {
            if collection.name.contains(matching) {
                collections.append(collection)
            }
        }
        return collections.map {
            CollectionEntity(collection: $0, modelData: modelData)
        }
    }
}

extension CollectionEntityQuery: EnumerableEntityQuery {
    func allEntities() async throws -> [CollectionEntity] {
        modelData.userCollections.map {
            CollectionEntity(collection: $0, modelData: modelData)
        }
    }
}
