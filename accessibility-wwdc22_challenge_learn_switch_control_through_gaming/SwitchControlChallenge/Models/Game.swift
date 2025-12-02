/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A game session with a score and a shuffled deck of cards.
*/

import Combine
import UIKit

class Game: ObservableObject {
    
    @Published private(set) var deck: Deck
    @Published var score: Int = 0
    @Published var didWinGame = false
    
    var cards: [Card] { deck.cards }
    
    private var currentlySelectedCardIndex: Int?
    
    private var numberOfCards: Int { cards.count }
    private var numberOfPairs: Int { numberOfCards / 2 }
    
    init(numberOfCards: Int) {
        deck = Deck(numberOfCards: numberOfCards)
        deck.shuffle()
    }
    
    func select(_ card: Card) {
        guard let requestedCardIndex = cards.firstIndex(where: { $0.id == card.id }) else { return }
        
        let requestedCard = cards[requestedCardIndex]
        
        guard !requestedCard.isFaceUp else { return }
        
        deck.cards[requestedCardIndex].isFaceUp = true
        
        if let currentlySelectedCardIndex = currentlySelectedCardIndex {
            let currentlySelectedCard = cards[currentlySelectedCardIndex]
            if requestedCard.symbol == currentlySelectedCard.symbol {
                // Match!
                Task { @MainActor in
                    score += 1
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    UIAccessibility.post(notification: .announcement, argument: "Found a match!")
                    deck.cards[requestedCardIndex].isMatched = true
                    deck.cards[currentlySelectedCardIndex].isMatched = true
                }
            } else {
                UIAccessibility.post(notification: .announcement, argument: "Not a match!")
                Task { @MainActor in
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    self.deck.cards[requestedCardIndex].isFaceUp = false
                    self.deck.cards[currentlySelectedCardIndex].isFaceUp = false
                }
            }
            self.currentlySelectedCardIndex = nil
        } else {
            for cardIndex in 0..<cards.count where cardIndex != requestedCardIndex {
                deck.cards[cardIndex].isFaceUp = false
            }
            currentlySelectedCardIndex = requestedCardIndex
        }
        
        if score == numberOfPairs {
            didWinGame = true
        }
    }
    
    func reset() {
        deck = Deck(numberOfCards: numberOfCards)
        deck.shuffle()
        score = 0
        didWinGame = false
        currentlySelectedCardIndex = nil
    }
}
