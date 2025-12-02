/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how to add an inline-style tip view.
*/


import SwiftUI
import TipKit

struct InlineTip: Tip {
    var title: Text {
        Text("Save as a Favorite")
    }

    var message: Text? {
        Text("Your favorite backyards always appear at the top of the list.")
    }

    var image: Image? {
        Image(systemName: "star")
    }
}

struct InlineView: View {
    // Create an instance of your tip content.
    let inlineTip = InlineTip()

    var body: some View {
        VStack(spacing: 20) {
            Text("A TipView embeds itself directly in the view. Make this style of tip your first choice as it doesn't obscure or hide any underlying UI elements.")

            // Place your tip near the feature you want to highlight.
            TipView(inlineTip, arrowEdge: .bottom)
            Button {
                // Invalidate the tip when someone uses the feature.
                inlineTip.invalidate(reason: .actionPerformed)
            } label: {
                Label("Favorite", systemImage: "star")
            }

            Text("To dismiss the tip, tap the close button in the upper right-hand corner of the tip or tap the Favorite button to use the feature, which then invalidates the tip programmatically.")
            Spacer()
        }
        .padding()
        .navigationTitle("Inline tip view")
    }
}

#Preview {
    InlineView()
}
