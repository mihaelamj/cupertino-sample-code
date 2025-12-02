/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The text messaging view that sends messages between players.
*/

import SwiftUI
import GameKit

struct ChatView: View {
    @ObservedObject var game: RealTimeGame
    @State private var typingMessage: String = ""
    
    var body: some View {
        VStack {
            // Show the opponent's name in the heading.
            HStack {
                Text("To: ").foregroundColor(Color.gray)
                game.opponentAvatar
                    .resizable()
                    .frame(width: 35.0, height: 35.0)
                    .clipShape(Circle())
                Text(game.opponentName)
            }
            .padding(10)
            
            // The view shows messages from others in this vertical stack.
            ScrollView {
                LazyVStack(alignment: .trailing, spacing: 6) {
                    ForEach(game.messages, id: \.id) { item in
                        MessageView(message: item)
                    }
                }
                .padding(10)
            }
            
            // The local player enters text messages to others here.
            HStack {
                TextField("Message...", text: $typingMessage)
                    .onSubmit {
                        game.sendMessage(content: typingMessage)
                        typingMessage = ""
                    }
                    .textFieldStyle(.roundedBorder)
                    .frame(minHeight: 30)
            }
            .frame(minHeight: 50)
            .padding()
        }
    }
}

struct ChatViewPreviews: PreviewProvider {
    static var previews: some View {
        ChatView(game: RealTimeGame())
    }
}
