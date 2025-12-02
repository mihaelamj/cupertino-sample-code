/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how to set a tip's display frequency.
*/


import SwiftUI
import TipKit

struct OptionTip: Tip {
    var title: Text {
        Text("Edit Actions in One Place")
    }

    var message: Text? {
        Text("Find actions such as Copy, Hide, Edit, and Paste under the \(Image(systemName: "ellipsis.circle"))  menu.")
    }

    var image: Image? {
        Image(systemName: "ellipsis.circle")
    }

    var options: [Option] {
        // Show this tip once.
        MaxDisplayCount(1)
    }
}

struct OptionView: View {
    // Create an instance of your tip content.
    let optionTip = OptionTip()

    var body: some View {
        VStack(spacing: 20) {
            Text("Use options to control the frequency your tips appear. For example, this tip is configured to only appear once. If you navigate back and then return, this tip no longer appears until you restart the app.")
            
            // Place your tip near the feature you want to highlight.
            TipView(optionTip, arrowEdge: .bottom)
            Image(systemName: "ellipsis.circle")
                .imageScale(.large)
            
            Text("Tap the button to toggle the app state and display the tip accordingly.")
            Spacer()
        }
        .padding()
        .navigationTitle("Tip options")
    }
}

#Preview {
    OptionView()
}
