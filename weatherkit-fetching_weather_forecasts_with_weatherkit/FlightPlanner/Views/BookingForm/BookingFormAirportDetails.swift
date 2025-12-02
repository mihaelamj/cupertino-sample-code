/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The airport details on the booking form for selecting the user's origin and
 destination airports.
*/

import SwiftUI

struct BookingFormAirportDetails: View {
    var airports: [Airport]
    var origin: Airport
    var destination: Airport?
    var journey: FlightJourney
    @Binding var activePickerRole: AirportPicker.Role?
    
    var body: some View {
        HStack(alignment: .flightLegArrow) {
            OriginAirportButton(origin: origin) {
                activePickerRole = .origin
            }
            Spacer()
            JourneyIcon(journey: journey)
            Spacer()
            DestinationAirportButton(destination: destination) {
                activePickerRole = .destination
            }
        }
    }
}

extension BookingFormAirportDetails {
    @MainActor
    init(
        airports: [Airport],
        inputData: BookingFormInputData,
        activePickerRole: Binding<AirportPicker.Role?>
    ) {
        self.init(
            airports: airports,
            origin: inputData.origin,
            destination: inputData.destination,
            journey: inputData.journey,
            activePickerRole: activePickerRole)
    }
}

private struct OriginAirportButton: View {
    var origin: Airport
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading) {
                Text("Origin")
                    .font(.caption)
                Text(origin.code)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct DestinationAirportButton: View {
    var destination: Airport?
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .trailing) {
                Text("Destination")
                    .font(.caption)
                Text(destination?.code ?? "Where to?")
                    .font(destination != nil ? .title : nil)
                    .fontWeight(destination != nil ? .bold : nil)
                    .foregroundStyle(destination != nil ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct JourneyIcon: View {
    var journey: FlightJourney

    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 44, height: 44)
            .padding()
            .overlay {
                Image(systemName: journey.systemImage)
                    .foregroundStyle(.background)
            }
            .alignmentGuide(.flightLegArrow) { dimensions in
                dimensions[VerticalAlignment.center]
            }
    }
}

struct BookingFormAirportDetails_Previews: PreviewProvider {
    static var previews: some View {
        let airports = [Airport.sfo, .mia, .pmi]
        return ForEach(FlightJourney.allCases) { journey in
            BookingFormAirportDetails(
                airports: airports,
                origin: .sfo,
                journey: journey,
                activePickerRole: .constant(nil))
        }
    }
}
