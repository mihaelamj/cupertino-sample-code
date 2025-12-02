/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Model object describing a single card in the game.
*/

import Foundation

struct Card: Identifiable {
    
    let id = UUID()
    var index = 0
    let symbol: Symbol
    var isFaceUp = false
    var isMatched = false
    
    var symbolName: String { symbol.symbolName }
    
    var accessibilityLabel: String { "Card \(index), \(isFaceUp ? symbol.accessibilityLabel : "Face Down")" }
}

