/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The location reminder data entry form.
*/

import SwiftUI

struct NewReminderForm: View {
    @Binding var entry: LocationReminderEntry
    var address: String
    
    private var preferredUnitLength: String {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        return formatter.string(from: UnitLength(forLocale: .current, usage: .asProvided))
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Reminder title", text: $entry.title, prompt: Text("Required"))
                    .autocorrectionDisabled(true)
            } header: {
                Text("Title")
            } footer: {
                Text("Enter the name of the reminder.")
            }
            
            Section("Priority") {
                Picker("Priority", selection: $entry.mappedPriority) {
                    ForEach(Priority.allCases) { priority in
                        Text(priority.title)
                            .tag(priority)
                    }
                }
            }
            
            Section {
                Picker("When", selection: $entry.mappedProximity) {
                    ForEach(Proximity.allCases) { proximity in
                        Text(proximity.title)
                            .tag(proximity)
                    }
                }
            } header: {
                Text("Triger Alarm")
            } footer: {
                Text("The system triggers an alarm when you enter or leave a given geofence.")
            }
            
            Section("Within Distance in \(preferredUnitLength)") {
                TextField("radius", value: $entry.radius, format: .number.precision(.fractionLength(2)))
            }
            Section("Near Location") {
                Text(address)
                    .font(.callout)
            }
        }
    }
}
