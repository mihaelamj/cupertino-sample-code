/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The row that displays flight segment information in the flight itinerary list.
*/

import SwiftUI

struct FlightSegmentRow: View {
    @Binding var selection: FlightLeg?
    var segment: FlightSegment
    var onDelete: ((IndexSet) -> Void)? = nil
    
    var body: some View {
        ForEach(segment.legs) { leg in
            NavigationLink(value: leg) {
                FlightLegRow(
                    leg: leg,
                    isSelected: leg == selection)
            }
        }
        .onDelete(perform: onDelete)
    }
}

struct FlightSegmentRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FlightSegmentRow(
                selection: .constant(nil),
                segment: .sfoToMiaToPmi)
            FlightSegmentRow(
                selection: .constant(.sfoToMia),
                segment: .sfoToMiaToPmi)
        }
    }
}
