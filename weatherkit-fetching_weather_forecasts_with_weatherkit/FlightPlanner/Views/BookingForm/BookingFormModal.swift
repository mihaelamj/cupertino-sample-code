/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The flight-booking form modal with a navigation stack and toolbar items.
*/

import SwiftUI

struct BookingFormModal: View {
    var flightData: FlightData
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @StateObject private var airportData = AirportData()
    @State private var inputData = BookingFormInputData()
    
    var body: some View {
        NavigationStack {
            BookingForm(airports: airports, inputData: $inputData)
                .navigationTitle("Add Your flight")
                .task {
                    Task.detached { @MainActor in
                        await airportData.load()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            Task {
                                await save()
                            }
                        }
                        .disabled(isSaveDisabled)
                    }
                }
        }
    }
    
    var airports: [Airport] {
        airportData.airports
    }
    
    func save() async {
        await inputData.save(to: flightData, in: calendar)
        dismiss()
    }
    
    var isSaveDisabled: Bool {
        inputData.destination == nil
    }
}

struct BookingFormSheet_Previews: PreviewProvider {
    static var previews: some View {
        BookingFormModal(flightData: FlightData(itinerary: [.sfoToMiaToPmi]))
    }
}
