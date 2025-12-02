/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Introduction page for the game.
*/

import SwiftUI

struct IntroPage: View {
    
    @Environment(\.dismiss) var dismiss
    
    let descriptions: [DescriptionPoint] = [
        .init(icon: "hand.tap.fill",
              headline: "Learn Switch Control!",
              body: "Learn how to use Switch Control by playing and winning this game!"),
        .init(icon: "rectangle.grid.3x2",
              headline: "Match Your Way to Victory!",
              body: "Memory Match Card Game"),
        .init(icon: "gearshape",
              headline: "Set up Switch Control",
              body: "Navigate to Settings to Set up Switch Control")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(alignment: .center) {
                    Text("Welcome to Memory Match!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding()
                        .frame(alignment: .center)
                }
                .padding()
                
                Spacer()
                
                VStack(alignment: .leading) {
                    ForEach(descriptions) { description in
                        HStack {
                            Image(systemName: description.icon)
                                .foregroundColor(.blue)
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text(description.headline)
                                    .fontWeight(.bold)
                                    .alignmentGuide(.leading) { $0[.leading] }
                                Text(description.body)
                                    .alignmentGuide(.leading) { $0[.leading] }
                            }
                        }
                        .padding()
                    }
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text("Continue")
                }
            }
        }
    }
}
struct IntroPage_Previews: PreviewProvider {
    static var previews: some View {
        IntroPage()
    }
}
