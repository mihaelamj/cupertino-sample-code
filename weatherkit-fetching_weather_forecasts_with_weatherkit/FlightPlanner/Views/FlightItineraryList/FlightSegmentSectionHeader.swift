/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The section header for each flight segment in the flight itinerary list.
*/

import SwiftUI

struct FlightSegmentSectionHeader: View {
    @Environment(\.calendar) private var calendar
    var segment: FlightSegment
    
    var body: some View {
        Text(hasSameDayFlights ? flightDate : flightDateRange)
            .font(.headline)
            .textCase(.none)
    }
    
    var hasSameDayFlights: Bool {
        calendar.isDate(departure, inSameDayAs: arrival)
    }
    
    var flightDate: LocalizedStringKey {
        "\(departure, style: .date)"
    }
    
    var flightDateRange: LocalizedStringKey {
        "\(departure, style: .date) – \(arrival, style: .date)"
    }

    var departure: Date {
        segment.departure
    }
    
    var arrival: Date {
        segment.arrival
    }
}

struct FlightListSectionHeader_Previews: PreviewProvider {
    static var previews: some View {
        FlightSegmentSectionHeader(segment: .sfoToMiaToPmi)
    }
}
