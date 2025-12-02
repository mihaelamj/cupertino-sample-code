/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI View representing a single card.
*/

import SwiftUI

struct CardView: View {
    
    let card: Card
    
    var body: some View {
        ZStack {
            if !card.isMatched {
                let shape = RoundedRectangle(cornerRadius: 20)
                shape
                    .fill().foregroundColor(card.isFaceUp ? .clear : .white)
                shape
                    .stroke(lineWidth: 4)
                    .foregroundColor(.init(uiColor: .lightGray))
                Image(systemName: card.isFaceUp ? card.symbolName : Symbol.inactive.symbolName)
                    .foregroundColor(card.isFaceUp ? card.symbol.color : .gray)
                    .font(card.isFaceUp ? .largeTitle : .title)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(card.accessibilityLabel)
        .accessibilityHidden(card.isMatched)
    }
}

