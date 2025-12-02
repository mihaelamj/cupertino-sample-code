/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A snippet that shows the resulting price for a ticket search.
*/

import AppIntents
import SwiftUI

struct TicketResultSnippetIntent: SnippetIntent {

    static let title: LocalizedStringResource = "Ticket Result Snippet"

    @Parameter var searchRequest: SearchRequestEntity

    func perform() async throws -> some IntentResult & ShowsSnippetView {
        switch searchRequest.status {
        case .pending:
            return .result(view: Text("Searching...").font(.title))
        case .completed:
            guard let price = searchRequest.finalPrice else {
                return .result(view: Text("No price found"))
            }
            return .result(
                view: LandmarkTicketPriceView(
                    landmark: searchRequest.landmark,
                    price: Double(price),
                    numberOfTickets: searchRequest.numberOfGuests
                )
            )
        }
    }
}

extension TicketResultSnippetIntent {
    init(searchRequest: SearchRequestEntity) {
        self.searchRequest = searchRequest
    }
}
