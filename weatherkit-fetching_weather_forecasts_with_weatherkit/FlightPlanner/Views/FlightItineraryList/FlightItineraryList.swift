/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main list that displays the user's flight itinerary arranged by segments.
*/

import SwiftUI

struct FlightItineraryList: View {
    @Binding var selection: FlightLeg?
    @Binding var segments: [FlightSegment]
    var onDelete: ((IndexSet, FlightSegment) -> Void)? = nil
    
    var body: some View {
        List(segments, selection: $selection) { segment in
            Section {
                FlightSegmentRow(
                    selection: $selection,
                    segment: segment) { offsets in
                    onDelete?(offsets, segment)
                }
            } header: {
                FlightSegmentSectionHeader(segment: segment)
            }
        }
    }
}

struct FlightList_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FlightItineraryList(
                selection: .constant(nil),
                segments: .constant([.sfoToMia]))
            FlightItineraryList(
                selection: .constant(.sfoToMia),
                segments: .constant([.sfoToMia]))
        }
    }
}
