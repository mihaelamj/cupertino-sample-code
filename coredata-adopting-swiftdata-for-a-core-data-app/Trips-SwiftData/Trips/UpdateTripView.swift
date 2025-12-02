/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that updates a trip.
*/

import SwiftUI
import SwiftData
import WidgetKit

struct UpdateTripView: View {
    var trip: Trip
    
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    @State private var name: String = ""
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var reason: PersonalTrip.Reason = .unknown
    @State private var perdiem: Double = 0.0
    
    var dateRange: ClosedRange<Date> {
        let start = Date.now
        let components = DateComponents(calendar: calendar,
                                        timeZone: timeZone, year: 1)
        let end = calendar.date(byAdding: components, to: start)!
        return start ... end
    }
    
    var body: some View {
        TripForm {
            Section(header: Text("Trip Title")) {
                TripGroupBox {
                    TextField(trip.name.isEmpty ? "Enter title here…" : trip.name, text: $name)
                }
                if trip is PersonalTrip {
                    TripGroupBox {
                        Picker("Reason", selection: $reason) {
                            ForEach(PersonalTrip.Reason.allCases) { reason in
                                Text(reason.rawValue.lowercased())
                            }
                        }
                    }
                }
            }
            
            if let businessTrip = trip as? BusinessTrip {
                Section(header: Text("Per diem")) {
                    TripGroupBox {
                        TextField("\(businessTrip.perdiem)", value: $perdiem, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    }
                }
            }
            
            Section(header: Text("Trip Destination")) {
                TripGroupBox {
                    TextField(trip.destination.isEmpty ? "Enter destination here…" : trip.destination,
                              text: $destination)
                }
            }
            
            Section(header: Text("Trip Dates")) {
                TripGroupBox {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Start Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $startDate,
                                       in: dateRange, displayedComponents: .date) {
                                Label("Start Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("End Date:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker(selection: $endDate,
                                       in: dateRange, displayedComponents: .date) {
                                Label("End Date", systemImage: "calendar")
                            }
                            .labelsHidden()
                        }
                    }
                }
            }
        }
        .onAppear {
            /**
             Populate the start and end dates of the trip.
             */
            startDate = trip.startDate
            endDate = trip.endDate
            if let personalTrip = trip as? PersonalTrip {
                reason = personalTrip.reason
            } else if let businessTrip = trip as? BusinessTrip {
                perdiem = businessTrip.perdiem
            }
        }
        .navigationTitle("Update Trip")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") {
                    updateTrip()
                    WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                    dismiss()
                }
            }
        }
    }

    private func updateTrip() {
        if !name.isEmpty {
            trip.name = name
        }
        
        if !destination.isEmpty {
            trip.destination = destination
        }
        
        trip.startDate = startDate
        trip.endDate = endDate
        if let personalTrip = trip as? PersonalTrip {
            personalTrip.reason = reason
        } else if let businessTrip = trip as? BusinessTrip {
            businessTrip.perdiem = perdiem
        }
    }
}

#Preview(traits: .sampleData) {
    @Previewable @Query var trips: [Trip]
    UpdateTripView(trip: trips.first!)
}
