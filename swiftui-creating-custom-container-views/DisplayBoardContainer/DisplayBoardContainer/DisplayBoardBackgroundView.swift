/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The background views of the main display board.
*/

import SwiftUI

struct DisplayBoardBackgroundView: View {
    var themeColor: Color = .brown.mix(with: .orange, by: 0.5)
    
    var body: some View {
        let backgroundShape = RoundedRectangle(cornerRadius: 10)
        let separatorColor = themeColor.mix(with: .black, by: 0.4)
        let frameColor = themeColor.mix(with: .black, by: 0.2)
        
        ZStack {
            frameColor
            
            ZStack {
                backgroundShape
                    .fill(separatorColor)
                
                backgroundShape
                    .inset(by: 2)
                    .fill(themeColor.shadow(.inner(
                        color: separatorColor.opacity(0.7),
                        radius: 2, x: 2, y: 2)))
            }
            .padding(44)
        }
    }
}

struct DisplayBoardSectionBackgroundView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 30)
            .fill(.black.opacity(0.05))
    }
}
