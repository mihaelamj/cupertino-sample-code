/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how to display a tip based on user state.
*/

import SwiftUI
import TipKit

struct EventRuleTip: Tip {
    // Define the user interaction you want to track.
    static let didTriggerControlEvent = Event(id: "didTriggerControlEvent")
    
    var title: Text {
        Text("Control it with a tap.")
    }

    var message: Text? {
        Text("Tap an icon to quickly turn an accessory on or off.")
    }

    var image: Image? {
        Image(systemName: "lock")
    }

    var rules: [Rule] {
        // Define a rule based on the user-interaction state.
        #Rule(Self.didTriggerControlEvent) {
            // Set the conditions for when the tip displays.
            $0.donations.count >= 3
        }
    }
}

struct EventRuleView: View {
    // Create an instance of your tip content.
    let eventRuleTip = EventRuleTip()

    var body: some View {
        VStack(spacing: 20) {
            Text("Use events to track user interactions in your app. Then define rules based on those interactions to control when your tips appear.")
            
            // Place your tip near the feature you want to highlight.
            TipView(eventRuleTip)
            Button(action: {
                // Donate to the event when the user action occurs.
                EventRuleTip.didTriggerControlEvent.sendDonation()
            }, label: {
                Label("Tap three times", systemImage: "lock")
            })
            
            Text("Tap the button above three times to make the tip appear.")
            Spacer()
        }
        .padding()
        .navigationTitle("Events")
    }
}

#Preview {
    EventRuleView()
}
