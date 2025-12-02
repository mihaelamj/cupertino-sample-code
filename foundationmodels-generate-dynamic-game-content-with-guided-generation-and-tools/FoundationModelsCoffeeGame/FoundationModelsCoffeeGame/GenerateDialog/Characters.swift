/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Models a character's name, personality, and default dialog lines.
*/

import Foundation
import FoundationModels

protocol Character: Identifiable {
    var id: UUID { get }
    var displayName: String { get }

    // Default scripted dialog to start the conversation.
    var firstLine: String { get }

    // Default line to restart a conversation
    var resumeConversationLine: String { get }

    // Detailed description of the character, their interests, and their relationships to others.
    var persona: String { get }

    // Default dialog if the model hits an error or the safety guardrails.
    var errorResponse: String { get }
}

struct Barista: Character {
    let id = UUID()
    let displayName = "Barista"
    let firstLine = "Hey there. Can you get the dream orders?"
    let resumeConversationLine = "Hey, I'm busy making coffee."

    let persona = """
        Chike is the head barista at Dream Coffee, and loves serving up the perfect cup of coffee
        to all the dreamers and creatures in the dream realm. Today is a particularly busy day, so
        Chike is happy to have the help of a new trainee barista named Player.
        """

    let errorResponse = "Maybe let's stop chatting? We've got coffee to serve."
}

struct CustomerLisa: Character {
    let id = UUID()
    let displayName = "Lisa"
    let firstLine =
        "I was dreaming of flying and decided to stop for a snack. This latte's pretty great!"

    let resumeConversationLine = "Hi!"

    let persona = """
        Lisa is a regular CUSTOMER at Dream Coffee, not a barista. She was just dreaming of flying \
        through the clouds on a magical set of wings. Now she's taking a break at Dream Coffee \
        to sip a latte and relax. Lisa is curious and friendly when meeting new people.
        """

    let errorResponse = "I'd really rather talk about coffee instead!"
}

@Generable
struct GeneratedCustomer: Character {
    let id = UUID()

    @Guide(description: "The name of the customer, like Namoi or Alex")
    let displayName: String

    let persona = "You are a CUSTOMER at Dream Coffee (NOT a barista) enjoying a cup of coffee"
    let encounter: Encounter
    let level: Int
    @Guide(.count(2))
    let attributes: [Attribute]

    @Guide(description: "A friendly greeting like hi or howdy")
    let resumeConversationLine: String

    @Guide(description: "Generate a friendly remark from this customer to the barista.")
    let firstLine: String

    @Generable
    enum Attribute {
        case sassy
        case tired
        case hungry
        case excited
        case nervous
    }

    @Generable
    enum Encounter {
        case newOrder
        case wantToTalkToManager
    }

    let errorResponse = "Sorry, let's talk about something else that involves more coffee!"
}
