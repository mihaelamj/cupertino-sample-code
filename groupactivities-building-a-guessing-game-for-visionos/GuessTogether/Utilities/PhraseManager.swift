/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A convenience type that provides a random secret phrase from the library to the game.
  The manager can filter by category and avoid providing the a phrase more than once.
*/

import Foundation

struct PhraseManager: Sendable {
    private let phrases: [String: [Phrase]]
    
    @MainActor
    static let shared = PhraseManager()
    
    init() {
        let phrasesJSON = Bundle.main.url(forResource: "Phrases", withExtension: "json")!
        guard let phrasesData = try? Data(contentsOf: phrasesJSON) else {
            fatalError("Phrase data not loaded.")
        }
        guard let decodedPhrases = try? JSONDecoder().decode([String: [String]].self, from: phrasesData) else {
            fatalError("Phrase data not decoded.")
        }
        
        phrases = Dictionary(
            uniqueKeysWithValues: decodedPhrases.map { category in
                let phrases = category.value.map { phraseDescription in
                    Phrase(category: category.key, description: phraseDescription)
                }
                
                return (category.key, phrases)
            }
        )
    }

    func randomPhrase(excludedCategories: Set<String>, usedPhrases: Set<Phrase>) -> Phrase {
        let categories = Set(phrases.keys).subtracting(excludedCategories)
        let possiblePhrases = Set(categories.flatMap { phrases[$0, default: []] })
        
        if possiblePhrases.isEmpty {
            fatalError("No phrases found in the given categories: \(categories)")
        }
        
        // Don't return secret phrases that have already been used.
        let newPhrases = possiblePhrases.subtracting(usedPhrases)
        if newPhrases.isEmpty {
            return possiblePhrases.randomElement()!
        } else {
            return newPhrases.randomElement()!
        }
    }
    
    var categories: [String] {
        return phrases.keys.sorted(using: KeyPathComparator(\.description))
    }
    
    struct Phrase: Codable, CustomStringConvertible, Hashable, Sendable {
        let category: String
        let description: String
    }
}
