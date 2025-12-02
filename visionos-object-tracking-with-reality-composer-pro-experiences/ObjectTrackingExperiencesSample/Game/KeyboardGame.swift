/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A game that manages a keyboard-based game where players respond to various challenges, progressing through different scenarios based on their inputs.
*/
import Foundation

class KeyboardGame {
    var currentChallenge: Challenge!
    var isPaused = false
    
    private var initialChallenge: Challenge!
    
    init() {
        self.initialChallenge = self.loadChallenges()
    }
    
    func loadChallenges() -> Challenge? {
        guard let url = Bundle.main.url(forResource: "Challenges", withExtension: "plist") else {
            AppLogger.logWarning("Could not find Challenges' plist file")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            let challenge = try decoder.decode(Challenge.self, from: data)
            return challenge
        } catch {
            AppLogger.logError("Error while loading initial challenge: \(error.localizedDescription)")
            return nil
        }
    }
    
    func startGame() {
        self.currentChallenge = initialChallenge
    }

    /// Responds to the current challenge with the given input.
    /// - Parameter input: Player input for the current challenge.
    /// - Returns: True, if the input is correct. False, otherwise.
    @discardableResult
    func respond(_ input: PlayerInput) -> Bool {
        if let availableOutcome = currentChallenge?.outcomes.first(where: { $0.playerInput == input }) {
            self.currentChallenge = availableOutcome.outcomeChallenge ?? initialChallenge
            return true
        } else if let availableOutcome = currentChallenge?.outcomes.first, availableOutcome.playerInput == .anyKey {
            self.currentChallenge = availableOutcome.outcomeChallenge ?? initialChallenge
            return true
        }
        return false
    }
}

/// Represents a game challenge, including its description and possible outcomes.
struct Challenge: Codable {
    let description: String
    let instructions: String?
    let sceneName: String?
    let outcomes: [Outcome]
    
    init(description: String, instructions: String? = nil, sceneName: String? = nil, outcomes: [Outcome]) {
        self.description = description
        self.instructions = instructions
        self.sceneName = sceneName
        self.outcomes = outcomes
    }
    
    var playerInput: PlayerInput? {
        self.outcomes.first?.playerInput
    }
    
    /// Represents the outcome of a challenge, linking a player's input to a potential outcome.
    struct Outcome: Codable {
        let playerInput: PlayerInput
        let outcomeChallenge: Challenge?
        
        init(playerInput: PlayerInput, outcomeChallenge: Challenge? = nil) {
            self.playerInput = playerInput
            self.outcomeChallenge = outcomeChallenge
        }
    }
}

/// Represents different types of player inputs in the game.
enum PlayerInput: Codable, Equatable {
    case anyKey
    case letter(String)
    case word(String)
    case keyCollision(String)
    
    enum CodingKeys: String, CodingKey {
        case type, value
    }
    
    enum InputFormat: String, Codable {
        case anyKey, letter, word, keyCollision
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(InputFormat.self, forKey: .type)
        switch type {
        case .anyKey:
            self = .anyKey
        case .letter:
            let value = try container.decode(String.self, forKey: .value)
            self = .letter(value)
        case .word:
            let value = try container.decode(String.self, forKey: .value)
            self = .word(value)
        case .keyCollision:
            let value = try container.decode(String.self, forKey: .value)
            self = .keyCollision(value)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .anyKey:
            try container.encode(InputFormat.anyKey, forKey: .type)
        case .letter(let value):
            try container.encode(InputFormat.letter, forKey: .type)
            try container.encode(value, forKey: .value)
        case .word(let value):
            try container.encode(InputFormat.word, forKey: .type)
            try container.encode(value, forKey: .value)
        case .keyCollision(let value):
            try container.encode(InputFormat.keyCollision, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}
