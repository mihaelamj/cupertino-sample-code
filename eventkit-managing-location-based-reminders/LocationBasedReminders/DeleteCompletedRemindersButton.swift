/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The delete completed reminders button.
*/

import SwiftUI

struct DeleteCompletedRemindersButton: View {
    @Binding var showDeleteConfirmation: Bool
    
    var body: some View {
        Button(role: .destructive) {
            showDeleteConfirmation.toggle()
        } label: {
            Label("Delete Completed", systemImage: "trash")
        }
    }
}
