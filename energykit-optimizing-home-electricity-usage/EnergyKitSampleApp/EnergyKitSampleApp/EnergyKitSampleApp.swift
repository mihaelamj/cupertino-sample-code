/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The EnergyKit sample app's entry point.
*/

import SwiftUI

/// The EnergyKit sample app's entry point.
@main
struct EnergyKitSampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: ChargingLocation.self)
    }
}

