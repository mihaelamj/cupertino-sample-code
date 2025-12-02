/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that displays the game play interface.
*/

import SwiftUI

struct GameView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var game: TurnBasedGame
    @State private var showMessages: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Display the game title.
            Text("Turn-Based Game")
                .font(.title)
            
            Form {
                Section("Game Data") {
                    HStack {
                        HStack {
                            game.myAvatar
                                .resizable()
                                .frame(width: 35.0, height: 35.0)
                                .clipShape(Circle())
                            
                            Text(game.myName + " (me)")
                                .lineLimit(2)
                        }
                        Spacer()
                        
                        Text("\(game.myItems)")
                            .lineLimit(2)
                    }
                    .listRowBackground(Rectangle().fill(game.myTurn ? .blue.opacity(0.25) : .white))
                    
                    HStack {
                        HStack {
                            game.opponentAvatar
                                .resizable()
                                .frame(width: 35.0, height: 35.0)
                                .clipShape(Circle())
                            
                            Text(game.opponentName)
                                .lineLimit(2)
                        }
                        Spacer()
                        
                        Text("\(game.opponentItems)")
                            .lineLimit(2)
                    }
                    .listRowBackground(Rectangle().fill(game.myTurn ? .white : .blue.opacity(0.25)))
                 
                    HStack {
                        Text("Count")
                            .lineLimit(2)
                        Spacer()
                        
                        Text("\(game.count)")
                    }
                    
                    if let matchMessage = game.matchMessage {
                        HStack {
                            Text(matchMessage)
                        }
                    }
                }
                Section("Game Controls") {
                    Button("Take Turn") {
                        Task {
                            await game.takeTurn()
                        }
                    }
                    .disabled(!game.myTurn)
                    
                    Button("Back") {
                        game.quitGame()
                    }
                    Button("Forfeit") {
                        Task {
                            await game.forfeitMatch()
                        }
                    }
                }
                Section("Exchanges") {
                    // Send a request to exchange an item.
                    Button("Exchange Item") {
                        Task {
                            await game.exchangeItem()
                        }
                    }
                    .disabled(game.opponent == nil)
                }
                Section("Communications") {
                    HStack {
                        // Send text messages as exchange items.
                        Button("Message") {
                            withAnimation(.easeInOut(duration: 1)) {
                                showMessages = true
                            }
                        }
                        .buttonStyle(MessageButtonStyle())
                        .onTapGesture {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    // Send a reminder to take their turn.
                    Button("Send Reminder") {
                        Task {
                            await game.sendReminder()
                        }
                    }
                    .disabled(game.myTurn)
                }
            }
        }
        // Display the text message view if it's enabled.
        .sheet(isPresented: $showMessages) {
            ChatView(game: game)
        }
        .alert("Game Over", isPresented: $game.youWon, actions: {
            Button("OK", role: .cancel) {
                game.resetGame()
            }
        }, message: {
            Text("You win.")
        })
        .alert("Game Over", isPresented: $game.youLost, actions: {
            Button("OK", role: .cancel) {
                game.resetGame()
            }
        }, message: {
            Text("You lose.")
        })
    }
}

struct GameViewPreviews: PreviewProvider {
    static var previews: some View {
        GameView(game: TurnBasedGame())
    }
}

struct MessageButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isPressed ? "bubble.left.fill" : "bubble.left")
                .imageScale(.medium)
            Text("Text Chat")
        }
        .foregroundColor(Color.blue)
    }
}
