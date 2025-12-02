/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to create a reminder using a map annotation or a person's current location.
*/

import SwiftUI
import MapKit

struct NewReminderEditor: View {
    @State private var entry = LocationReminderEntry()
    @State private var address = "Unknown Address"
    
    @Environment(\.dismiss) private var dismiss
    @Environment(ReminderStoreManager.self) private var storeManager
    
    var annotation: MapAnnotation?
    var location: CLLocation?
    
    private var shouldEnableButton: Bool {
        !entry.title.isEmpty && entry.proximity != .none && storeManager.defaultListExists
    }
    
    var body: some View {
        NewReminderForm(entry: $entry, address: address)
            .onAppear {
                Task {
                    if let annotation {
                        address = await annotation.location.reversedGeocodedLocation()
                    } else if let location {
                        address = await location.reversedGeocodedLocation()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("New Reminder")
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        performSave()
                    } label: {
                        Label("Save", systemImage: "square.and.arrow.down.fill")
                    }
                    .labelStyle(.titleOnly)
                    .foregroundStyle(.white)
                    .disabled(!shouldEnableButton)
                }
            }
    }
    
    func performSave() {
        addNewReminder()
        dismiss()
    }
    /*
       The system calls this function when a person taps the save button in the toolbar. The app
       creates a new location-based reminder using the specified map item or map annotation.
    */
    func addNewReminder() {
        let newLocationReminder = LocationReminderEntry(title: entry.title,
                                                        radius: entry.radius,
                                                        priority: entry.mappedPriority,
                                                        proximity: entry.mappedProximity)
        
        Task {
            if let annotation {
                await storeManager.add(newLocationReminder, annotation: annotation)
            } else if let location {
                await storeManager.add(newLocationReminder, location: location)
            }
        }
    }
}

#Preview {
    NewReminderEditor()
        .environment(ReminderStoreManager())
}
