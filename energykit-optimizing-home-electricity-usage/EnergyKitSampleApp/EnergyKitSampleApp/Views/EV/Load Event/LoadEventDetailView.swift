/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The load event details view.
*/

import EnergyKit
import SwiftUI

/// The load event details view.
struct LoadEventDetailView: View {
    var event: ElectricVehicleLoadEvent

    var body: some View {
        List {
            Section(header: Text("Description").textCase(.uppercase)) {
                UUIDTextView(attribute: "Device ID:", uuid: event.deviceID)
                UUIDTextView(attribute: "Event ID:", uuid: event.id.uuidString)
            }
            
            Section(header: Text("Session Information").textCase(.uppercase)) {
                UUIDTextView(
                    attribute: "Session ID:",
                    uuid: event.session.id.uuidString
                )
                AttributeValueTextView(
                    attribute: "Session State:",
                    value: "\(event.session.state)"
                )
                AttributeValueTextView(
                    attribute: "State Of Charge:",
                    value: "\(event.measurement.stateOfCharge) %"
                )
                AttributeValueTextView(
                    attribute: "Charging Power:",
                    value: "\(event.measurement.power.formatted())"
                )
                AttributeValueTextView(
                    attribute: "Cumulative Electricity:",
                    value: "\(event.measurement.energy.formatted())"
                )
                AttributeValueTextView(
                    attribute: "Guidance Token:",
                    value: "\(event.session.guidanceState.guidanceToken)"
                )
                AttributeValueTextView(
                    attribute: "Guidance State:",
                    value: event.session.guidanceState.wasFollowingGuidance ? "Following" : "Not following"
                )
            }
        }
        .listStyle(.inset)
        .navigationTitle("Load Event Details")
    }
}
