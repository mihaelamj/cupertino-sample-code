/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how to add an action button that displays another view.
*/

import SwiftUI
import TipKit

struct LearnMoreTip: Tip {
    var title: Text {
        Text("Search and Filter with Tags")
    }

    var message: Text? {
        Text("Add tags to easily find messages across all your conversations. Just type a tag like #games anywhere in your message.")
    }

    var image: Image? {
        Image(systemName: "number")
    }

    var actions: [Action] {
        // Define a learn more button.
        Action(id: "learn-more", title: "Learn More")
    }
}

struct LearnMoreView: View {
    // Create an instance of your tip content.
    let learnMoreTip = LearnMoreTip()

    @State private var showLearnMoreSheet = false

    var body: some View {
        VStack(spacing: 20) {
            Text("To provide additional context around how a tip can be used, consider displaying an additional view for more information.")

            // Place your tip near the feature you want to highlight.
            TipView(learnMoreTip, arrowEdge: .bottom) { action in
                if action.id == "learn-more" {
                    showLearnMoreSheet = true
                }
            }

            Button("Search") {}
            Text("Tap the Learn More action button within the tip to learn more about the feature.")
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showLearnMoreSheet) {
            LearnMoreSheetView()
        }
        .navigationTitle("Learn more")
    }
}

struct LearnMoreSheetView: View {
    @Environment(\.dismiss)
    var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "number")
                .resizable()
                .scaledToFit()
                .frame(width: 160)
                .foregroundColor(.accentColor)
            Text("Why Tags?")
                .font(.title)
            Text("""
                Tags let you quickly search and organize your messages.

                Just type your tag anywhere in the body of a message. You can use the tag browser to filter or find messages based on tags.
                """)
            .foregroundStyle(.secondary)
            Button("Dismiss") {
                dismiss()
            }
        }
        .padding(.horizontal, 40)
    }
}

#Preview {
    LearnMoreView()
}

