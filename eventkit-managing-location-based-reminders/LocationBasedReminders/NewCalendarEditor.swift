/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to create a list.
*/

import SwiftUI

struct NewCalendarEditor: View {
    @State private var name: String = ""
    @State private var selectedSourceID: SourceModel.ID?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(ReminderStoreManager.self) private var manager
    
    /*
      The app enables the save button in the toolbar when the person enters a
      name for the new list and selects a source. It disables it, otherwise.
    */
    private var shouldEnableSaveButton: Bool {
        !name.isEmpty && selectedSourceID != nil
    }
    
    var body: some View {
        NavigationStack {
            List(selection: $selectedSourceID) {
                Section {
                    TextField("New List", text: $name)
                        .autocorrectionDisabled(true)
                }
                
                Section {
                    ForEach(manager.sources) { source in
                        Text(source.title)
                    }
                } header: {
                    Text("Select Source")
                }
            }
            .task {
                await manager.fetchLatestSources()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New List")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        performSave()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down.fill")
                    }
                    .labelStyle(.titleOnly)
                    .foregroundStyle(.white)
                    .disabled(!shouldEnableSaveButton)
                }
            }
        }
    }
    
    func performSave() {
        addNewCalendar()
        dismiss()
    }
    
    /*
       The system calls this function when the person taps the save button in the toolbar.
       The app creates a new list with the name the person enters and saves it
       in the source identified by `selectedSourceID`.
    */
    func addNewCalendar() {
        Task {
            if let selectedSourceID {
                await manager.addList(with: name, inSourceWithID: selectedSourceID)
            }
        }
    }
}
