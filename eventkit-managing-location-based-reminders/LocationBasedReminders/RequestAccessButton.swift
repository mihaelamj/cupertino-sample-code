/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button that prompts the person for access to reminders.
*/

import SwiftUI

struct RequestAccessButton: View {
    @Environment(ReminderStoreManager.self) private var manager
    
    var body: some View {
        // The app displays this view If the person hasn't approved or denied the app access, yet.
        ContentUnavailableView {
            Label("Unknown Access", systemImage: "person.fill.questionmark")
        } description: {
            Text("The app requires access to read and write your location-based reminders.")
                .multilineTextAlignment(.leading)
        } actions: {
            requestButton
        }
    }
    
    /// Prompts the person for full access to their reminder data.
    private var requestButton: some View {
        Button {
            Task {
                await manager.setupEventStore()
            }
        } label: {
            Text("Request Access")
        }
    }
}

#Preview {
    RequestAccessButton()
        .environment(ReminderStoreManager())
}
