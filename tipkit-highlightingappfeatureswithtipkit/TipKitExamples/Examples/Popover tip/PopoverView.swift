/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how to add a popover-style tip view.
*/


import SwiftUI
import TipKit

struct PopoverTip: Tip {
    var title: Text {
        Text("Add an Effect")
            .foregroundStyle(.indigo)
    }

    var message: Text? {
        Text("Touch and hold \(Image(systemName: "wand.and.stars")) to add an effect to your favorite image.")
    }
}

struct PopoverView: View {
    // Create an instance of your tip content.
    let popoverTip = PopoverTip()

    var body: some View {
        VStack(spacing: 20) {
            Text("Popover views display on top of UI elements. Use this tip view if you don’t want the layout of the screen to change, and are OK with underlying UI elements being obscured or hidden.")
            Text("Lorem ipsum dolor sit amet, consect etur adi piscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                .foregroundStyle(.tertiary)

            Image(systemName: "wand.and.stars")
                .imageScale(.large)
                // Add the popover to the feature you want to highlight.
                 .popoverTip(popoverTip)
                .onTapGesture {
                    // Invalidate the tip when someone uses the feature.
                    popoverTip.invalidate(reason: .actionPerformed)
                }

            Text("Lorem ipsum dolor sit amet, consect etur adi piscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consect etur adi piscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding()
        .navigationTitle("Popover tip view")
    }
}

#Preview {
    PopoverView()
}

