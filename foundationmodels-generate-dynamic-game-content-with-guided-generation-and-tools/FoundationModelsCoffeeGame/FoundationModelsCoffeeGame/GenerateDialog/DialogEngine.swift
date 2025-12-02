/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view model that generates a character's dialog in response to the player.
*/

import FoundationModels
import SwiftUI

@MainActor
@Observable class DialogEngine {
    var talkingTo: (any Character)?
    var nextUtterance: String?
    var isGenerating = false

    private var session: LanguageModelSession?
    private var currentTask: Task<Void, Never>?
    private var conversations: [UUID: LanguageModelSession] = [:]

    /// A list of words that the NPCs don't want to talk about because they love coffee.
    private var blockWords: [String] = ["tea", "smoothie", "milkshake"]

    /// A list of phrases that the NPCs shouldn't be distracted by.
    private var blockPhrases: [String] = ["Are we dreaming"]

    func talkTo(_ character: any Character) {
        Logging.general.log("Talking to: \(self.talkingTo?.displayName ?? "no one")")
        talkingTo = character
        if conversations[character.id] == nil {
            nextUtterance = character.firstLine
            resetSession(character, startWith: character.firstLine)
        } else {
            nextUtterance = character.resumeConversationLine
        }
        self.session = conversations[character.id]
    }

    func textIsOK(_ input: String) -> Bool {
        if input.lowercased().split(separator: " ").allSatisfy({
            !blockWords.contains($0.lowercased())
        }) {
            return blockPhrases.allSatisfy({ !input.lowercased().contains($0.lowercased()) })
        }
        return false
    }

    func respond(_ userInput: String) {
        nextUtterance = "... ... ..."

        guard let character = talkingTo, let session else {
            if let session {
                Logging.general.log("Session: \(String(describing: session))")
            }
            return
        }
        // check if input contains any blocked word/phrases
        guard textIsOK(userInput) else {
            nextUtterance = character.errorResponse
            return
        }

        // continue the conversation
        isGenerating = true
        currentTask = Task {
            do {
                let response = try await session.respond(
                    to: userInput
                )
                let dialog = response.content
                Logging.general.log("Response: \(dialog)")
                Logging.general.log("\(String(describing: session.transcript))")

                // check if output contains any blocked words/phrases
                if textIsOK(dialog) {
                    nextUtterance = dialog
                    isGenerating = false
                } else {
                    Logging.general.log("Block list rejected response: \(dialog)")
                    nextUtterance = character.errorResponse
                    isGenerating = false
                    resetSession(character, startWith: character.resumeConversationLine)
                }
            } catch let error as LanguageModelSession.GenerationError {
                if case .exceededContextWindowSize(let context) = error {
                    Logging.general.log("Context window exceeded: \(context.debugDescription)")
                    resetSession(character, previousSession: session)
                    nextUtterance = character.errorResponse
                    isGenerating = false
                } else {
                    Logging.general.log("Generation error: \(error)")
                    nextUtterance = character.errorResponse
                    isGenerating = false
                }
            } catch let error {
                Logging.general.log("Other error: \(error)")
                nextUtterance = character.errorResponse
                isGenerating = false
            }
        }
    }

    private func resetSession(_ character: any Character, previousSession: LanguageModelSession) {
        let allEntries = previousSession.transcript
        var condensedEntries = [Transcript.Entry]()
        if let firstEntry = allEntries.first {
            condensedEntries.append(firstEntry)
            if allEntries.count > 1, let lastEntry = allEntries.last {
                condensedEntries.append(lastEntry)
            }
        }
        let condensedTranscript = Transcript(entries: condensedEntries)
        // Note: transcript includes instructions.
        // check if tool should be included
        var newSession: LanguageModelSession
        if let customer = character as? GeneratedCustomer {
            newSession = LanguageModelSession(
                tools: [CalendarTool(contactName: customer.displayName)],
                transcript: condensedTranscript
            )
        } else {
            newSession = LanguageModelSession(transcript: condensedTranscript)
        }
        newSession.prewarm()
        conversations[character.id] = newSession
    }

    private func resetSession(_ character: any Character, startWith: String) {
        let instructions = """
            A multi-turn conversation between a game character and the player of this game. \
            You are \(character.displayName). Refer to \(character.displayName) in the 1st person \
            (like "I" or "me"). You MUST respond in the voice of \(character.persona).\

            Keep your responses short and positive. Remember: since this is the dream realm, \
            everything is free at this coffee shop and the baristas are paid in creative inpiration.

            You just said: "\(startWith)"
            """
        var newSession: LanguageModelSession

        // check if tool should be included
        if let customer = character as? GeneratedCustomer {
            newSession = LanguageModelSession(
                tools: [CalendarTool(contactName: customer.displayName)],
                instructions: instructions
            )
        } else {
            newSession = LanguageModelSession(instructions: instructions)
        }
        newSession.prewarm()
        conversations[character.id] = newSession
    }

    func endConversation() {
        currentTask?.cancel()
        nextUtterance = nil
        if let talkingTo {
            resetSession(talkingTo, previousSession: conversations[talkingTo.id]!)
        }
        talkingTo = nil
        isGenerating = false
    }
}
