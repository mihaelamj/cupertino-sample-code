/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view for the app.
*/

import SwiftUI

/// The root view of the app's one window group scene.
struct ContentView: View {
    var body: some View {
        VStack {
            Spacer()
            Profile()
            Spacer()
            Leaderboard()
            Spacer()
            ButtonStack()
                .padding(.bottom)
        }
    }
}

/// A SwiftUI preview provider for the app's main content view.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(Model.previewData)
    }
}
