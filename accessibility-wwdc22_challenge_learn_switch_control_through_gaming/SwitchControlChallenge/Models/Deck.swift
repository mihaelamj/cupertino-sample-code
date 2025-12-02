/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A deck of cards for the memory matching game.
*/

import Foundation

struct Deck {
    
    var cards: [Card]
    
    init(numberOfCards: Int) {
        let pairTotal = numberOfCards / 2
        let symbols = Symbol.symbolSet(numberOfPairs: pairTotal)
        cards = [Card]()
        
        for index in 0..<pairTotal {
            let symbol = symbols[index]
            for _ in 0..<2 {
                cards.append(Card(symbol: symbol))
            }
        }
    }
    
    // Shuffle the playing cards and update the index of the card in the array.
    mutating func shuffle() {
        cards.shuffle()
        for index in 0..<cards.count {
            cards[index].index = index
        }
    }
    
    func getCard(byID id: UUID) -> Card? {
        if let index = cards.firstIndex(where: { $0.id == id }) {
            return getCard(byIndex: index)
        }
        
        return nil
    }
    
    func getCard(byIndex index: Int) -> Card? {
        guard index < cards.count else {
            return nil
        }
        
        return cards[index]
    }
    
    mutating func toggle(card: Card) {
        if let selectedIndex = cards.firstIndex(where: { $0.id == card.id }) {
            cards[selectedIndex].isFaceUp.toggle()
        }
    }
    
    mutating func isMatch(selectedCard: Card, candidateCard: Card) -> Bool {
        if selectedCard.isMatched || selectedCard.isFaceUp {
            return false
        }
        
        if selectedCard.symbol != candidateCard.symbol {
            return false
        }
        
        cards[selectedCard.index].isMatched = true
        cards[candidateCard.index].isMatched = true
        
        return true
    }
}

