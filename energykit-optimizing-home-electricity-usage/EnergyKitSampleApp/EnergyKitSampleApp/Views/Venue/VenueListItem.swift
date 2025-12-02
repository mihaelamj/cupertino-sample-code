/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The energy-venue list item view.
*/

import EnergyKit
import SwiftUI

/// The energy-venue list item view.
struct VenueListItem: View {
    var venue: EnergyVenue

    var body: some View {
        HStack {
            Image(systemName: "bolt.fill")
                .imageScale(.large)
                .foregroundStyle(.green)
            VStack(alignment: .leading) {
                Text(venue.name)
                    .font(.headline.leading(.tight))
                    .foregroundStyle(.primary)
                Text(venue.id.uuidString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
