/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to display and manage location reminders.
*/

import SwiftUI

struct ReminderList: View {
    @State private var isDeleteConfirmationpresented: Bool = false
    @State private var isMapPresented: Bool = false
    @State private var isSettingsPresented: Bool = false
    @State private var priority: Priority = .high
    @State private var showCompleted: Bool = false
    @State private var sort: ReminderSortValue = .title
   
    @Environment(ReminderStoreManager.self) private var manager
    
    /// The app organizes location reminders by priority.
    private var reminders: [LocationReminder] {
        manager.locationReminders
            .filter { $0.geofence.priority == priority }
    }
    
    /*
       The app implements a button that toggles between the show completed and
       hide completed values. If the person taps show completed, the app presents
       all incomplete and completed location-based reminders. If the person taps
       hide completed, the app limits the data to incomplete ones.
    */
    private var filteredReminders: [LocationReminder] {
        let result = showCompleted ? reminders.incomplete : reminders
            .reminders(sortedBy: sort)
        return result
    }
    
    /*
      Displays a list of location-based reminders available in all the person's
      lists. The app provides a menu that allows the user to display incomplete,
      or incomplete and completed reminders. Additionally, the person can decide
      to view these data sorted by creation date, due date, or title. Toggles
      the button next to a reminder to complete it or make it incomplete.
    */
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Priority", selection: $priority) {
                ForEach(Priority.allCases.reversed()) { priority in
                    Text(priority.title)
                        .tag(priority)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom)
            
            List {
                ForEach(filteredReminders) { reminder in
                    ReminderRow(reminder: reminder)
                }
                .onDelete(perform: removeReminders)
            }
            .listStyle(.plain)
            .task {
                await manager.fetchLatestReminders()
            }
            .overlay {
                if reminders.isEmpty {
                    noReminders
                } else if filteredReminders.isEmpty {
                    noIncompleteReminders
                }
            }
        }
        .alert("Delete Completed Location Reminders?", isPresented: $isDeleteConfirmationpresented) {
            DeleteConfirmationButton(reminders: reminders.completed)
        } message: {
            Text("This will delete all completed location reminders with the selected priority in the app.")
        }
        .sheet(isPresented: $isMapPresented) {
            MapView()
        }
        .toolbar {
            ToolbarItemGroup {
                addAnnotationButon
                if !reminders.isEmpty {
                    sortMenu
                }
            }
        }
    }
    
    private func removeReminders(at offsets: IndexSet) {
        let remindersToDelete = offsets.map { filteredReminders[$0] }
        Task {
            await manager.removeLocationReminders(remindersToDelete)
        }
    }
    
    /// The app displays a map with annotations when the person taps the plus button in the toolbar.
    private var addAnnotationButon: some View {
        Button {
            isMapPresented.toggle()
        } label: {
            Label("Add map annotation", systemImage: "plus")
        }
    }
    
    /// The app shows this view when fetching all reminders returns no result.
    private var noReminders: some View {
        ContentUnavailableView {
            Label("No Reminders", systemImage: "text.badge.plus")
        } description: {
            Text("Add some location reminders with the priority the app displays.")
        }
    }
    
    /// The app shows this view when fetching incomplete reminders returns no result.
    private var noIncompleteReminders: some View {
        ContentUnavailableView {
            Label("No Incomplete Reminders", systemImage: "text.badge.checkmark")
        } description: {
            Text("You've completed all your location reminders with the selected priority the app displays. Add more!")
        }
    }
    
    private var sortMenu: some View {
        Menu {
            // Sorts the reminders by creation date or title in ascending order.
            SortPicker(sort: $sort)
            
            /*
                The app fetches complete and incomplete location reminders. If the
                fetch operation returns some complete reminders, the app displays
                the delete completed button, and shows either the completed or hide completed button. If
                the operation doesn't, the app disables these buttons.
            */
            if !reminders.completed.isEmpty {
                ToggleCompletionButton(showCompleted: $showCompleted)
                DeleteCompletedRemindersButton(showDeleteConfirmation: $isDeleteConfirmationpresented)
            }
            
        } label: {
            Label("Layout Options", systemImage: "ellipsis.circle")
                .labelStyle(.iconOnly)
        }
    }
}

#Preview {
    ReminderList()
        .environment(ReminderStoreManager())
}
