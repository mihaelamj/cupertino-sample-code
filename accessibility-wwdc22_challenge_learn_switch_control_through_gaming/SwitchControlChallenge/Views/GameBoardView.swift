/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
SwiftUI view representing the full board of cards for a game.
*/

import SwiftUI

struct GameBoardView: View {
    
    static let numberOfCards = 16
    
    @StateObject var viewModel = Game(numberOfCards: Self.numberOfCards)
    @State var isIntroPresented = true
    @State var isPopoverPresented = false
    
    var body: some View {
        NavigationView {
            ZStack {
                if !viewModel.didWinGame {
                    VStack {
                        ForEach([Int](0..<Self.numberOfCards / 4), id: \.self) { row in
                            HStack {
                                ForEach(viewModel.cards[(4 * row)..<(4 * row) + 4]) { card in
                                    CardView(card: card)
                                        .aspectRatio(2 / 3, contentMode: .fit)
                                        .onTapGesture {
                                            // Only playable via Switch Control!
                                        }
                                        .accessibilityAction {
                                            viewModel.select(card)
                                        }
                                }
                            }
                            .accessibilityElement(children: .contain)
                        }
                        .accessibilityElement(children: .contain)
                        .padding(.horizontal)
                        .foregroundColor(.red)
                    }
                } else {
                    VStack {
                        Image("Win")
                        Text("You Win!")
                            .font(.title)
                        Text("Congrats on learning Switch Control!")
                            .font(.subheadline)
                            .padding()
                        Button {
                            viewModel.reset()
                        } label: {
                            Text("Play Again")
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(Text("Memory Match"))
            .popover(isPresented: $isPopoverPresented) {
                VStack {
                    Text("No Taps Allowed!")
                        .font(.title)
                        .padding()
                    Text("Only Switch Control can be used to win.")
                        .font(.body)
                        .padding()
                    Button {
                        isPopoverPresented = false
                    } label: {
                        Text("Got it!")
                    }
                    .padding()
                    Button {
                        isPopoverPresented = false
                        isIntroPresented = true
                    } label: {
                        Text("Help!")
                    }
                }
            }
        }
        .sheet(isPresented: $isIntroPresented) {
            IntroPage()
        }
    }
}

struct GameBoardView_Previews: PreviewProvider {
    static var previews: some View {
        GameBoardView()
    }
}
