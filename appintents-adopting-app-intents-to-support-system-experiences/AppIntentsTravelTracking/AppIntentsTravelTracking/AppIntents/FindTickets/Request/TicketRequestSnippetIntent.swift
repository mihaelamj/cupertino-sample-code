/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A snippet intent presents the view that modifies the number of tickets for the ticket search.
*/

import AppIntents
import SwiftUI

struct TicketRequestSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Ticket Request Snippet"

    @Parameter var searchRequest: SearchRequestEntity

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let view = TicketRequestView(searchRequest: searchRequest)

        return .result(view: view)
    }
}

extension TicketRequestSnippetIntent {
    init(searchRequest: SearchRequestEntity) {
        self.searchRequest = searchRequest
    }
}

