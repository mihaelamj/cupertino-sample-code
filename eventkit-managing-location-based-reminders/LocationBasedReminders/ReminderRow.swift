/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The location reminder row view.
*/

import SwiftUI

struct ReminderRow: View {
    @Environment(ReminderStoreManager.self) private var manager
    var reminder: LocationReminder
    
    var body: some View {
        Label {
            VStack(alignment: .leading) {
                Text(reminder.title)
                    .font(.title3)
                Text(reminder.geofenceAsText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: reminder.image)
                .imageScale(.large)
                .foregroundStyle(reminder.calendarColor)
                .onTapGesture {
                    Task {
                        await manager.completeLocationReminder(reminder)
                    }
                }
        }
    }
}
