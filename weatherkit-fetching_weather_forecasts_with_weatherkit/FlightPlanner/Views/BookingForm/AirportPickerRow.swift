/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The row for the airport picker control that the flight-booking form presents.
*/

import SwiftUI

struct AirportPickerRow: View {
    var airport: Airport
    
    var body: some View {
        Text(airport.city)
            .bold() +
        Text(" ") +
        Text("(\(airport.code))")
    }
}
