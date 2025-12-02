/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The home page of the real-time game.
*/

import SwiftUI
import GameKit

struct ContentView: View {
    @StateObject private var game = RealTimeGame()
    @State private var showFriends = false
    
    var body: some View {
        VStack {
            // Display the game title.
            Text("Real-Time Game")
                .font(.title)
                .padding()
            Form {
                Section("Start Game") {
                    Button("Choose Player") {
                        if game.automatch {
                            // Turn automatch off.
                            GKMatchmaker.shared().cancel()
                            game.automatch = false
                        }
                        game.choosePlayer()
                    }
                    
                    Toggle("Automatch", isOn: $game.automatch)
                    .foregroundColor(.blue)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: game.automatch) { state in
                        if game.automatch {
                            // Turn automatch on.
                            Task {
                                await game.findPlayer()
                            }
                        } else {
                            // Turn automatch off.
                            GKMatchmaker.shared().cancel()
                        }
                    }
                }
                Section("Game Center Data") {
                    Button("My Achievements") {
                        game.showProgress()
                    }
                    
                    Button("Top Scores") {
                        game.topScore()
                    }
                }
                Section("Friends") {
                    Button("Add Friends") {
                        game.addFriends()
                    }
                    
                    Button("Access Friends") {
                        Task {
                            await game.accessFriends()
                            showFriends = true
                            GKAccessPoint.shared.isActive = false
                        }
                    }
                }
            }
            .disabled(!game.matchAvailable)
        }
        // Authenticate the local player when the game first launches.
        .onAppear {
            if !game.playingGame {
                game.authenticatePlayer()
            }
        }
            
        // Display the game interface if a match is ongoing.
        .fullScreenCover(isPresented: $game.playingGame) {
            GameView(game: game)
        }
        
        // Display the local player's friends.
        .sheet(isPresented: $showFriends, onDismiss: {
            showFriends = false
            GKAccessPoint.shared.isActive = true
        }) {
            FriendsView(game: game)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
