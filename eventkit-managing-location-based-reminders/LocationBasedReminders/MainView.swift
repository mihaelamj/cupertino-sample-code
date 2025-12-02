/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that verifies the existence of a default list for reminders.
*/

import SwiftUI

struct MainView: View {
    @State private var isCalendarEditorPresented: Bool = false
    @State private var sources: [SourceModel] = []
    @Environment(ReminderStoreManager.self) private var manager
    
    /*
       The app verifies the existence of a default list for saving reminders.
       If the list exists, the app displays all location-based reminders available
       in all of the person's calendars. If the list doesn't, the app prompts the
       person to create a new list.
    */
    var body: some View {
        VStack {
            if manager.defaultListExists {
                ReminderList()
            } else {
                ContentUnavailableView {
                    Label("No List", systemImage: "calendar.circle")
                } description: {
                    Text("No default list for reminders on this device. The app requires a list to create and fetch location reminders.")
                        .multilineTextAlignment(.leading)
                } actions: {
                    addListButton
                }
                .navigationTitle("Location Reminders")
            }
        }
        .sheet(isPresented: $isCalendarEditorPresented) {
            NewCalendarEditor()
        }
    }
    
    private var addListButton: some View {
        Button {
            isCalendarEditorPresented.toggle()
        } label: {
            Label("Add List", systemImage: "plus")
        }
    }
}
