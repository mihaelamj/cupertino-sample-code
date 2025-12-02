/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The passenger details on the booking form for selecting the user's passengers.
*/

import SwiftUI

struct BookingFormPassengerDetails: View {
    @Binding var passengerInfo: PassengerInfo
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Passengers")
                .font(.caption)
            PassengersStepper(value: $passengerInfo.adultsCount) {
                Text("Adults: \(passengerInfo.adultsCount)")
                Text("Over 12 years old")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } label: {
                Label("Adults", systemImage: "person")
            }
            PassengersStepper(value: $passengerInfo.childrenCount) {
                Text("Children: \(passengerInfo.childrenCount)")
                Text("Between 2 and 11 years old")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } label: {
                Label("Children", systemImage: "person")
            }
            PassengersStepper(value: $passengerInfo.infantsCount) {
                Text("Infants: \(passengerInfo.infantsCount)")
                Text("Under 2 years old")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } label: {
                Label("Infants", systemImage: "person")
            }
        }
    }
}

private struct PassengersStepper<Content: View, Label: View>: View {
    @Binding var value: Int
    var content: Content
    var label: Label
    private let min = 0
    private let max = 8
    
    init(
        value: Binding<Int>,
        @ViewBuilder content: () -> Content,
        @ViewBuilder label: () -> Label
    ) {
        _value = value
        self.content = content()
        self.label = label()
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                content
            }
            Spacer()
            Stepper {
                label
            } onIncrement: {
                guard value < max else { return }
                value += 1
            } onDecrement: {
                guard value > min else { return }
                value -= 1
            }
        }
    }
}

struct BookingFormPassengerDetails_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(0..<4, id: \.self) { count in
            let passengerInfo = PassengerInfo(
                adultsCount: count,
                childrenCount: count,
                infantsCount: count)
            BookingFormPassengerDetails(passengerInfo: .constant(passengerInfo))
        }
    }
}
