/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The load event list item view.
*/

import EnergyKit
import SwiftUI

/// The load event list item view.
struct LoadEventListItem: View {
    var event: ElectricVehicleLoadEvent

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 64, height: 64)
                .foregroundStyle(event.session.guidanceState.wasFollowingGuidance ? .green : .red)
                .overlay {
                    Image(systemName: "bolt.car")
                        .imageScale(.large)
                }
                .padding(.trailing)

            VStack(alignment: .leading) {
                AttributeValueTextView(
                    attribute: "State of Charge:",
                    value: "\(event.measurement.stateOfCharge)%"
                )
                AttributeValueTextView(
                    attribute: "Session State:",
                    value: "\(event.session.state)"
                )
                AttributeValueTextView(
                    attribute: "Cumulative Electricity:",
                    value: "\(event.measurement.energy.formatted())"
                )
                AttributeValueTextView(
                    attribute: "Timestamp:",
                    value: "\(event.timestamp.formatted(.dateTime.month().day().hour().minute()))"
                )
            }
        }
    }
}
