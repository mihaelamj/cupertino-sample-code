/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent that starts the process to find the cheapest tickets for a landmark.
*/

import AppIntents

struct FindTicketsIntent: AppIntent {

    static let title: LocalizedStringResource = "Find Tickets"

    static var parameterSummary: some ParameterSummary {
        Summary("Find best ticket prices for \(\.$landmark)")
    }
    
    @Dependency var searchEngine: SearchEngine

    @Parameter var landmark: LandmarkEntity

    func perform() async throws -> some IntentResult & ShowsSnippetIntent {
        let searchRequest = await searchEngine.createRequest(landmarkEntity: landmark)

        // Present a snippet that allows people to change
        // the number of tickets.
        try await requestConfirmation(
            actionName: .search,
            snippetIntent: TicketRequestSnippetIntent(searchRequest: searchRequest)
        )

        // If the person has confirmed the action, perform the ticket search.
        try await searchEngine.performRequest(request: searchRequest)

        // Show the result of the ticket search.
        return .result(
            snippetIntent: TicketResultSnippetIntent(
                searchRequest: searchRequest
            )
        )
    }
}

extension FindTicketsIntent {
    init(landmark: LandmarkEntity) {
        self.landmark = landmark
    }
}
