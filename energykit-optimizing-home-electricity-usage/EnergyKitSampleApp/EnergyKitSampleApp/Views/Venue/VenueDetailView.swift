/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The energy-venue details view.
*/

import EnergyKit
import SwiftUI

/// The energy-venue details view.
struct VenueDetailView: View {
    @Environment(EnergyVenueManager.self) var energyVenueManager
    @State private var electricVehicleModel: ElectricVehicleController?

    var body: some View {
        List {
            Section(header: Text("Description").textCase(.uppercase)) {
                AttributeValueTextView(attribute: "Name:", value: energyVenueManager.venue.name)
                UUIDTextView(attribute: "Identifier:", uuid: energyVenueManager.venue.id.uuidString)
            }

            if let guidance = energyVenueManager.guidance {
                Section(header: Text("Electricity Guidance (Forecast)").textCase(.uppercase)) {
                    GuidanceChart(guidance: guidance)
                }
                .onAppear {
                    // Initialize EV model with venue and guidance.
                    electricVehicleModel = .init(
                        venue: energyVenueManager.venue,
                        guidance: guidance
                    )
                }

                if let electricVehicleModel {
                    Section(header: Text("Electric Vehicles").textCase(.uppercase)) {
                        EVView().environment(electricVehicleModel)
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Venue Details")
    }
}
