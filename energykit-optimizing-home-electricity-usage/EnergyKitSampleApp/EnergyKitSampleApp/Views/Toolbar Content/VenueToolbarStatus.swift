/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The energy-venue toolbar status view of the app.
*/

import Foundation
import SwiftUI

/// The energy-venue toolbar status view of the app.
struct VenueToolbarStatus: View {
    var isLoading: Bool
    var venuesCount: Int

    var body: some View {
        let venuesCountStr = venuesCount == 0 ? "No venues found" : "\(venuesCount) venues found"
        VStack {
            if isLoading {
                Text("Checking for venues...")
                Spacer()
            } else {
                Text(venuesCountStr)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }
}
