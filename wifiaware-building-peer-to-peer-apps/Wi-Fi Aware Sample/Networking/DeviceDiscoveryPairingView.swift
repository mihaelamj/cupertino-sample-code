/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The DeviceDiscoveryUI views for pairing.
*/

import DeviceDiscoveryUI
import WiFiAware
import SwiftUI
import Network
import OSLog

struct DeviceDiscoveryPairingView: View {
    let mode: SimulationEngine.Mode

    var body: some View {
        if mode == .viewer {
            DevicePicker(.wifiAware(.connecting(to: .userSpecifiedDevices, from: .simulationService))) { endpoint in
                logger.info("Paired Endpoint: \(endpoint)")
            } label: {
                AddDeviceButton()
            } fallback: {
                AddDeviceButton(fallback: true)
            }
        } else {
            DevicePairingView(.wifiAware(.connecting(to: .simulationService, from: .userSpecifiedDevices))) {
                AddDeviceButton()
            } fallback: {
                AddDeviceButton(fallback: true)
            }
        }
    }
}

struct AddDeviceButton: View {
    let fallback: Bool

    init(fallback: Bool = false) {
        self.fallback = fallback
    }

    var body: some View {
        HStack {
            if fallback {
                Image(systemName: "xmark.circle")
                Text("Unavailable")
            } else {
                Image(systemName: "plus")
            }
        }
        .glassEffectButton()
    }
}
