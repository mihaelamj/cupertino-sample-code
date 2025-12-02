/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The delete confirmation button.
*/

import SwiftUI

struct DeleteConfirmationButton: View {
    @Environment(ReminderStoreManager.self) private var manager
    var reminders: [LocationReminder]
    
    var body: some View {
        Button(role: .destructive) {
            deleteCompletedReminders()
        } label: {
            Text("Delete")
        }
    }
    
    /// Deletes the given completed reminders from the person's lists.
    private func deleteCompletedReminders() {
        Task {
            await manager.removeLocationReminders(reminders)
        }
    }
}
