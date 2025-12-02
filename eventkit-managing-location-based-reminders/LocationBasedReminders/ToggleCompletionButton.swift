/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button the person can use to filter completed location reminders.
*/

import SwiftUI

struct ToggleCompletionButton: View {
    @Binding var showCompleted: Bool
    
    var body: some View {
        Button {
            showCompleted.toggle()
        } label: {
            Label(showCompleted ? "Show Completed" : "Hide Completed", systemImage: "eye")
                .symbolVariant(showCompleted ? .none : .slash)
        }
    }
}

#Preview {
    ToggleCompletionButton(showCompleted: .constant(true))
    ToggleCompletionButton(showCompleted: .constant(false))
}
