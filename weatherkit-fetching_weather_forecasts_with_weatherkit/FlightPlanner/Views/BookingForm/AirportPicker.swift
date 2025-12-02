/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The airport picker that the flight-booking form presents.
*/

import SwiftUI

struct AirportPicker: View {
    enum Role: Int, CaseIterable, Identifiable {
        case origin
        case destination
        
        var id: Int { rawValue }
    }
    
    var airports: [Airport]
    @Binding var role: Role?
    @Binding var inputData: BookingFormInputData
    
    var body: some View {
        NavigationView {
            Group {
                if role == .origin {
                    originAirportList
                } else if role == .destination {
                    destinationAirportList
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        role = nil
                    }
                    .disabled(role == nil || role == .origin)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        role = nil
                    }
                    .disabled(isDoneDisabled)
                }
            }
        }
    }
    
    @MainActor
    var originAirportList: some View {
        List(selection: originSelection) {
            ForEach(airports, id: \.id) { airport in
                AirportPickerRow(airport: airport)
                    .tag(airport)
            }
        }
        .navigationTitle("Where from?")
    }
    
    @MainActor
    var originSelection: Binding<Airport?> {
        Binding<Airport?> {
            inputData.origin
        } set: { newValue in
            if let airport = newValue {
                inputData.origin = airport
            }
        }
    }
    
    @MainActor
    var destinationAirportList: some View {
        List(selection: $inputData.destination) {
            ForEach(destinationAirports) { airport in
                AirportPickerRow(airport: airport)
                    .tag(airport)
            }
        }
        .navigationTitle("Where to?")
    }
    
    @MainActor
    var destinationAirports: [Airport] {
        airports.filter { $0 != inputData.origin }
    }
    
    @MainActor
    var isDoneDisabled: Bool {
        role == nil || role == .destination && inputData.destination == nil
    }
}

struct AirportPicker_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(AirportPicker.Role.allCases) { role in
            AirportPicker(
                airports: [.sfo, .mia, .pmi],
                role: .constant(role),
                inputData: .constant(BookingFormInputData()))
        }
    }
}
