/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main content view for the game.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            GameBoardView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
