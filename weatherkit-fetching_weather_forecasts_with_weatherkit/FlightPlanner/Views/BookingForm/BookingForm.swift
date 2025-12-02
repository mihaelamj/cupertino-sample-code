/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The flight-booking form for selecting the journey type, origin and destination,
 dates, and number of passengers to add flights to the user's flight itinerary.
*/

import SwiftUI

struct BookingForm: View {
    var airports: [Airport]
    @Binding var inputData: BookingFormInputData
    @Environment(\.calendar) private var calendar
    @State private var activeAirportPickerRole: AirportPicker.Role?
    
    var body: some View {
        Form {
            JourneyPicker(selection: $inputData.journey)
                .padding(.bottom)
            BookingFormAirportDetails(
                airports: airports,
                inputData: inputData,
                activePickerRole: $activeAirportPickerRole)
            BookingFormDateDetails(inputData: $inputData)
            BookingFormPassengerDetails(passengerInfo: $inputData.passengerInfo)
        }
        .labelsHidden()
        .sheet(item: $activeAirportPickerRole) { role in
            AirportPicker(
                airports: airports,
                role: $activeAirportPickerRole,
                inputData: $inputData)
        }
    }
}

struct BookingFormContent_Previews: PreviewProvider {
    static var previews: some View {
        let airports = [Airport.sfo, .mia, .pmi]
        let inputData = BookingFormInputData()
        return BookingForm(airports: airports, inputData: .constant(inputData))
    }
}
