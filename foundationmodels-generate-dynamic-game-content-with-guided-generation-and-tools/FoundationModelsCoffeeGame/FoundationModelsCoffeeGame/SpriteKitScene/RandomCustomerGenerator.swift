/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility class that generates a customer based on the player's contacts.
*/

import FoundationModels

@MainActor
class RandomCustomerGenerator {
    private static let contactsTool = ContactsTool()
    let session = LanguageModelSession(
        tools: [contactsTool],
        instructions: """
            Use the \(contactsTool.name) tool to get a name for a customer.
            """
    )

    func generate() async throws -> GeneratedCustomer {
        let prompt = """
            Generate a friendly customer enjoying their coffee. This customer should have a name \
            from your contacts.
            """
        let response = try await session.respond(
            to: prompt,
            generating: GeneratedCustomer.self
        )
        return response.content
    }
}
