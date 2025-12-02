/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view model that generates a customer with their image, name, and order.
*/

import FoundationModels
import SwiftUI

@Generable
struct NPC: Equatable {
    let name: String

    let coffeeOrder: String

    let picture: GenerableImage
}

@MainActor
@Observable class EncounterEngine {
    var customer: NPC?

    func generateNPC() async throws -> NPC {
        do {
            let session = LanguageModelSession {
                """
                A conversation between a user and a helpful assistant. This is a fantasy RPG game that takes
                place at Dream Coffee, the beloved coffee shop of the dream realm. Your role is to use your
                imagination to generate fun game characters.
                """
            }
            let prompt = """
                Create an NPC customer with a fun personality suitable for the dream realm. Have the customer order
                coffee. Here are some examples to inspire you:
                {name: "Thimblefoot", imageDescription: "A horse with a rainbow mane",
                coffeeOrder: "I would like a coffee that's refreshing and sweet like grass of a summer meadow"}
                {name: "Spiderkid", imageDescription: "A furry spider with a cool baseball cap",
                coffeeOrder: "An iced coffee please, that's as spooky as me!"}
                {name: "Wise Fairy", imageDescription: "A blue glowing fairy that radiates wisdom and sparkles",
                coffeeOrder: "Something simple and plant-based please, that will restore my wise energy."}
                """
            let npc = try await session.respond(
                to: prompt,
                generating: NPC.self,
            ).content
            Logging.general.log("Generated NPC: \(String(describing: npc))")
            return npc
        }
    }

    func judgeDrink(drink: CoffeeDrink) async -> String {
        do {
            if let customer {
                let session = LanguageModelSession {
                    """
                    A conversation between a user and a helpful assistant. This is a fantasy RPG game that takes
                    place at Dream Coffee, the beloved coffee shop of the dream realm. Your role is to pretend to be
                    the following customer:
                    \(customer.name): \(customer.picture.imageDescription)
                    """
                }
                let prompt = """
                    You have just ordered the following drink:
                    \(customer.coffeeOrder)
                    The barista has just made you this drink:
                    \(drink)
                    Does this drink match your expectations? Do you like it? You MUST respond with helpful feedback for
                    the barista. If you like your drink, give it a compliment! If you hate your drink, politely tell the
                    barista why.
                    """
                return try await session.respond(to: prompt).content
            }
        } catch let error {
            Logging.general.log("Generation error: \(error)")
        }
        return "Hmm... it's ok!"
    }
}
