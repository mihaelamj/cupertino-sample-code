/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to display and delete monthly events.
*/

import SwiftUI
import EventKit

struct EventList: View {
    @EnvironmentObject var storeManager: EventStoreManager
    @State private var shouldPresentError: Bool = false
    @State private var alertMessage: String?
    @State private var alertTitle: String?
    @State var selection: Set<EKEvent> = []
    @State var editMode: EditMode = .inactive
    
    /*
        Displays a list of events that occur within this month in all the user's calendars. Removes an event from Calendar when the user deletes it
        from the list.
    */
    var body: some View {
            VStack {
                if storeManager.events.isEmpty {
                    MessageView(message: .events)
                } else {
                    List(selection: $selection) {
                        ForEach(storeManager.events, id: \.self) { event in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(event.title)
                                    .foregroundColor(.primary)
                                    .font(.headline)
                                HStack {
                                    Text(event.startDate, style: .date)
                                        .foregroundStyle(.primary)
                                        .font(.caption)
                                    Text("at")
                                        .foregroundStyle(.primary)
                                        .font(.caption)
                                    Text(event.startDate, style: .time)
                                        .foregroundStyle(.primary)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    .toolbar(content: toolbarContent)
                    .environment(\.editMode, $editMode)
                }
            }
            .alertErrorMessage(message: alertMessage, title: alertTitle, isPresented: $shouldPresentError)
    }
    
    /// Delete the selected event from Calendar.
    func removeEvents(_ events: [EKEvent]) {
        Task {
            do {
                try await storeManager.removeEvents(events)
                selection.removeAll()
            } catch {
                showError(error, title: "Delete failed.")
            }
        }
    }
    
    func showError(_ error: Error, title: String) {
        alertTitle = title
        alertMessage = error.localizedDescription
        shouldPresentError = true
    }
}

struct EventList_Previews: PreviewProvider {
    static var previews: some View {
        EventList()
            .environmentObject(EventStoreManager())
    }
}
