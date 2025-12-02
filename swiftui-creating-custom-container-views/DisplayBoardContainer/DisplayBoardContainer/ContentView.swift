/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view that hosts a display board with pinned notes.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        DisplayBoardV5 {
            Section("Person1’s\nFavorites") {
                Text("Song 1")
                    .displayBoardCardRejected(true)
                Text("Song 2")
                Text("Song 3")
            }
            Section("Person2’s\nFavorites") {
                ForEach(Songs.fromPerson2) { song in
                    Text(song.title)
                        .displayBoardCardRejected(song.person2CalledDibs)
                }
            }
            Section("Person3’s\nFavorites") {
                ForEach(Songs.fromPerson3) { song in
                    Text(song.title)
                }
            }
            .displayBoardCardRejected(true)
        }
        .ignoresSafeArea()
    }
}

#Preview(traits: .landscapeLeft) {
    ContentView()
}
