/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how to combine two display rules into one.
*/

import SwiftUI
import TipKit

struct ComboTip: Tip {
    // Define the user interaction you want to track.
    static let enteredView = Event(id: "enteredView")
    
    var title: Text {
        Text("Save as a Favorite")
    }

    var message: Text? {
        Text("Your favorite backyards always appear at the top of the list.")
    }

    var image: Image? {
        Image(systemName: "star")
    }

    // Note: These rules AND together.
    var rules: [Rule] {
        // Define a parameter-based rule tracking app state.
        #Rule(ContentView.$isLoggedIn) {
            $0 == true
        }
        // Define an event-based rule tracking user state.
        #Rule(Self.enteredView) {
            $0.donations.count >= 3
        }
    }
}

struct ComboView: View {
    // Create an instance of your tip content.
    let comboTip = ComboTip()

    var body: some View {
        VStack(spacing: 20) {
            Text("You can combine parameters, events, and options to support more complex conditions for displaying tips.")

            // Place your tip near the feature you want to highlight.
            TipView(comboTip, arrowEdge: .bottom)
            Image(systemName: "star")

            Button(ContentView.isLoggedIn ? "Logout" : "Login") {
                ContentView.isLoggedIn.toggle()
            }

            Text("Entered view: \(ComboTip.enteredView.donations.count + 1) times")
            Text("For example, to make this tip appear, navigate in and out of the screen three times, and then tap the Login button.")
            Spacer()
        }
        .onAppear {
            // Donate to the event each time the view appears.
            ComboTip.enteredView.sendDonation()
        }
        .padding()
        .navigationTitle("Combining rules")
    }
}

#Preview {
    ComboView()
}
