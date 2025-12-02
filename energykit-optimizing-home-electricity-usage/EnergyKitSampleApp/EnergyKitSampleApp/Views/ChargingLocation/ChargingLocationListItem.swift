/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI list item view that shows charging location metadata.
*/

import EnergyKit
import SwiftUI

struct ChargingLocationListItem: View {
    @Bindable var chargingLocation: ChargingLocation

    @Environment(\.modelContext) var modelContext
    @State private var showVenueDetails = false

    var body: some View {
        NavigationLink(value: chargingLocation) {
            HStack {
                VStack(alignment: .leading) {
                    Text(chargingLocation.energyVenueName)
                        .font(.headline)
                    Toggle(isOn: $chargingLocation.isCECEnabled) {
                        Text("\(Image(systemName: "bolt.fill")) Clean Energy Charging")
                    }
                }
            }
        }
    }
}
