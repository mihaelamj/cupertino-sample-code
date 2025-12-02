/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App entity representing a search request.
*/

import AppIntents

struct SearchRequestEntity: AppEntity {

    static let defaultQuery = SearchRequestQuery()

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Search Request"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(landmark.name) tickets search request",
        )
    }

    var id: String

    @Property var landmark: LandmarkEntity
    @Property var numberOfGuests: Int
    @Property var status: SearchStatus
    @Property var finalPrice: Double?
}

extension SearchRequestEntity {
    init(id: String, landmark: LandmarkEntity, numberOfGuests: Int, status: SearchStatus, finalPrice: Double?) {
        self.id = id
        self.landmark = landmark
        self.numberOfGuests = numberOfGuests
        self.finalPrice = finalPrice
        self.status = status
    }
}

struct SearchRequestQuery: EntityQuery {
    @Dependency var searchEngine: SearchEngine

    func entities(for identifiers: [SearchRequestEntity.ID]) async throws -> [SearchRequestEntity] {
        var results: [SearchRequestEntity] = []
        for identifier in identifiers {
            guard let request = await searchEngine.requests[identifier] else { continue }

            results.append(request)
        }

        return results
    }

}
