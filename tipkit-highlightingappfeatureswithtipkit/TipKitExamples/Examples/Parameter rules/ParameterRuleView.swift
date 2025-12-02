/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how to display a tip based on app state.
*/

import SwiftUI
import TipKit

struct ParameterRuleTip: Tip {
    var title: Text {
        Text("Change Your Photo View")
    }

    var message: Text? {
        Text("Switch between your friend's library and your own.")
    }

    var image: Image? {
        Image(systemName: "photo.on.rectangle")
    }

    var rules: [Rule] {
        // Define a rule based on the app state.
        #Rule(ContentView.$isLoggedIn) {
            // Set the conditions for when the tip displays.
            $0 == true
        }
    }
}

struct ParameterRuleView: View {
    // Create an instance of your tip content.
    let parameterRuleTip = ParameterRuleTip()

    var body: some View {
        VStack(spacing: 20) {
            Text("Use the parameter property wrapper and rules to track app state and control where and when your tip appears.")
            
            // Place your tip near the feature you want to highlight.
            TipView(parameterRuleTip, arrowEdge: .bottom)
            Image(systemName: "photo.on.rectangle")
                .imageScale(.large)

            Button("Tap") {
                // Trigger a change in app state to make the tip appear or disappear.
                ContentView.isLoggedIn.toggle()
            }

            Text("Tap the button to toggle the app state and display the tip accordingly.")
            Spacer()
        }
        .padding()
        .navigationTitle("Parameter rules")
    }
}

#Preview {
    ParameterRuleView()
}
