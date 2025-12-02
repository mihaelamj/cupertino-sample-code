/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The load-events toolbar status view of the app.
*/

import Foundation
import SwiftUI

/// The load-events toolbar status view of the app.
struct LoadEventsToolbarStatus: View {
    var eventsCount: Int

    var body: some View {
        let leCountStr = eventsCount == 0 ? "No events found" : "\(eventsCount) load events found"
        Text(leCountStr)
            .foregroundStyle(.secondary)
            .font(.caption)
    }
}
