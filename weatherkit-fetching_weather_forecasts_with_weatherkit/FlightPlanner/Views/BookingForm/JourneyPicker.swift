/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The flight journey picker that displays on the flight-booking form.
*/
import SwiftUI

struct JourneyPicker: View {
    @Binding var selection: FlightJourney
    private var data: [FlightJourney]
    
    init(
        _ data: [FlightJourney] = FlightJourney.allCases,
        selection: Binding<FlightJourney>
    ) {
        self.data = data
        _selection = selection
    }
    
    var body: some View {
        Picker(selection: $selection) {
            ForEach(data) { journey in
                Text(journey.title)
                    .tag(journey)
            }
        } label: {
            Label("Journey", systemImage: selection.systemImage)
        }
        .pickerStyle(.segmented)
    }
}

struct JourneyPicker_Previews: PreviewProvider {
    static var previews: some View {
        JourneyPicker(selection: .constant(.roundTrip))
    }
}
