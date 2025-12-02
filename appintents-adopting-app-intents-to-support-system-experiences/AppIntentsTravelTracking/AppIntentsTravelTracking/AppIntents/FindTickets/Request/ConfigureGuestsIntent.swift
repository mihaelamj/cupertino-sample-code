/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An intent that modifies the number of guests for a ticket's search request.
*/

import AppIntents

struct ConfigureGuestsIntent: AppIntent {

    static let title: LocalizedStringResource = "Configure Guests"

    /// Setting this property to false hides it from Shortcuts. Since this is not useful
    /// as a standalone action.
    static let isDiscoverable: Bool = false

    @Dependency var searchEngine: SearchEngine

    @Parameter var searchRequest: SearchRequestEntity
    @Parameter var numberOfGuests: Int

    func perform() async throws -> some IntentResult {
        await searchEngine.setGuests(to: numberOfGuests, searchRequest: searchRequest)

        return .result()
    }
}

extension ConfigureGuestsIntent {
    init(searchRequest: SearchRequestEntity, numberOfGuests: Int) {
        self.searchRequest = searchRequest
        self.numberOfGuests = numberOfGuests
    }
}
