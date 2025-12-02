/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sort by reminder picker.
*/

import SwiftUI

struct SortPicker: View {
    @Binding var sort: ReminderSortValue
    
    var body: some View {
        /// Allows a person to sort reminders by creation date, due date, or title.
        Picker("Sort by", selection: $sort) {
            ForEach(ReminderSortValue.allCases) { value in
                Label(value.title, systemImage: value.systemImage)
            }
        }
    }
}

#Preview {
    SortPicker(sort: .constant(.title))
}
