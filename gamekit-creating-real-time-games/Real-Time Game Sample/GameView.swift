/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that displays the game play interface.
*/

import SwiftUI
import GameKit

struct GameView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var game: RealTimeGame
    @State private var showMessages = false
    @State private var isChatting = false
    
    var body: some View {
        VStack {
            // Display the game title.
            Text("Real-Time Game")
                .font(.title)
            
            Form {
                Section("Game Data") {
                    // Display the local player's avatar, name, and score.
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
                        
                        Text("\(game.myScore)")
                            .lineLimit(2)
                    }
                    
                    // Display the opponent's avatar, name, and score.
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
                        
                        Text("\(game.opponentScore)")
                            .lineLimit(2)
                    }
                }
                .listItemTint(.blue)
                
                Section("Game Controls") {
                    Button("Take Action") {
                        game.takeAction()
                    }

                    Button("End Game") {
                        game.endMatch()
                    }
                    
                    Button("Forfeit") {
                        game.forfeitMatch()
                    }
                }
                Section("Communications") {
                    HStack {
                        // Send text messages.
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
                    HStack {
                        // Voice chat with the opponent.
                        Toggle("Chat", isOn: $isChatting)
                            .onChange(of: isChatting) { value in
                                if value == true {
                                    game.startVoiceChat()
                                } else {
                                    game.stopVoiceChat()
                                }
                            }
                            .toggleStyle(ChatToggleStyle())
                            .disabled(!GKVoiceChat.isVoIPAllowed())
                    }
                }
                Section("Rules") {
                    Text("First player to reach 10 points more than their opponent wins.")
                }
            }
        }
        .sheet(isPresented: $showMessages, onDismiss: {
            showMessages = false
        }) {
            ChatView(game: game)
        }
        .alert("Game Over", isPresented: $game.youForfeit, actions: {
            Button("OK", role: .cancel) {
                game.resetMatch()
            }
        }, message: {
            Text("You forfeit. Opponent wins.")
        })
        .alert("Game Over", isPresented: $game.opponentForfeit, actions: {
            Button("OK", role: .cancel) {
                // Save the score when the opponent forfeits the game.
                game.saveScore()
                game.resetMatch()
            }
        }, message: {
            Text("Opponent forfeits. You win.")
        })
        .alert("Game Over", isPresented: $game.youWon, actions: {
            Button("OK", role: .cancel) {
                //  Save the score when the local player wins.
                game.saveScore()
                game.resetMatch()
            }
        }, message: {
            Text("You win.")
        })
        .alert("Game Over", isPresented: $game.opponentWon, actions: {
            Button("OK", role: .cancel) {
                game.resetMatch()
            }
        }, message: {
            Text("You lose.")
        })
    }
}

struct ChatToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        return HStack {
            Image(systemName: configuration.isOn ? "phone.fill" : "phone")
                .imageScale(.medium)
                .onTapGesture { configuration.isOn.toggle() }
            Text("Voice Chat")
        }
        .foregroundColor(Color.blue)
    }
}

struct MessageButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        return HStack {
            Image(systemName: configuration.isPressed ? "bubble.left.fill" : "bubble.left")
                .imageScale(.medium)
            Text("Text Chat")
        }
        .foregroundColor(Color.blue)
    }
}

struct GameViewPreviews: PreviewProvider {
    static var previews: some View {
        GameView(game: RealTimeGame())
    }
}
