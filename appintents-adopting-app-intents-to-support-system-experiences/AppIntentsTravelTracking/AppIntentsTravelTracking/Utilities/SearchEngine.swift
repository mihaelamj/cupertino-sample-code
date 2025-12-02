/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that contains the app's search functionality.
*/

import Foundation
import AppIntents

enum SearchStatus: String, AppEnum {
    case pending
    case completed

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Search Status"

    static let caseDisplayRepresentations: [SearchStatus: DisplayRepresentation] = [
        .pending: "Pending",
        .completed: "Completed"
    ]
}

actor SearchEngine {
    static let shared = SearchEngine()

    var requests: [String: SearchRequestEntity] = [:]

    func createRequest(landmarkEntity: LandmarkEntity) -> SearchRequestEntity {
        let id = UUID().uuidString

        let result = SearchRequestEntity(
            id: id,
            landmark: landmarkEntity,
            numberOfGuests: 1,
            status: .pending,
            finalPrice: nil
        )
        requests[id] = result

        return result
    }

    func request<Value>(id: String, set keyPath: WritableKeyPath<SearchRequestEntity, Value>, to value: Value) {
        guard var request = requests[id] else {
            return
        }

        request[keyPath: keyPath] = value

        requests[id] = request
    }

    func setGuests(to count: Int, searchRequest: SearchRequestEntity) {
        self.request(id: searchRequest.id, set: \.numberOfGuests, to: count)
    }

    func setStatus(id: String, status: SearchStatus) {
        self.request(id: id, set: \.status, to: status)
    }

    func performRequest(request: SearchRequestEntity) async throws {
        // Set to pending status...
        let id = request.id

        self.setStatus(id: id, status: .pending)

        TicketResultSnippetIntent.reload()

        try await Task.sleep(for: .seconds(2))

        // Kick off search...

        self.setStatus(id: id, status: .completed)
        await self.request(id: id, set: \.finalPrice, to: price(for: id))

        TicketResultSnippetIntent.reload()
    }

    func price(for id: String) async -> Double {

        let pricePerPerson: Double = Double.random(in: 20...25)

        return pricePerPerson * Double(requests[id]!.numberOfGuests)
    }
}
