/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view of the watchOS app.
*/

import SwiftUI
import UserNotifications

/// This view displays an interface for discovering and connecting to Bluetooth peripherals.
struct RootView: View {
    
    @EnvironmentObject private var receiver: BluetoothReceiver
    private var notificationHandler = ExtensionDelegate.instance.notificationHandler

    /// A button to start and stop the scanning process.
    private var scanButton: some View {
        Button("\(receiver.isScanning ? "Scanning..." : "Scan")") {
            toggleScanning()
        }
    }
    
    /// A switch to enable the scan to alert functionality.
    private var alertScanSwitch: some View {
        Toggle("Scan to alert", isOn: $receiver.scanToAlert)
    }
    
    /// A view to list the peripherals that the system discovers during the scan.
    var discoveredPeripherals: some View {
        ForEach(Array(receiver.discoveredPeripherals), id: \.identifier) { peripheral in
            Text(peripheral.name ?? "unnamed peripheral")
                .onTapGesture { receiver.connect(to: peripheral) }
        }
    }
    
    /// A view to display the Bluetooth peripheral that this device is currently connected to.
    @ViewBuilder
    var connectedPeripheral: some View {
        if let peripheral = receiver.connectedPeripheral {
            Text(peripheral.name ?? "unnamed peripheral")
                .onTapGesture { receiver.disconnect(from: peripheral, mustDisconnect: true) }
        }
    }
    
    var body: some View {
        List {
            scanButton.foregroundColor(Color.blue)
            alertScanSwitch.foregroundColor(Color.blue)
            Section(header: Text("Connected")) {
                connectedPeripheral
            }
            Section(header: Text("Discovered")) {
                discoveredPeripherals
            }
        }
    }
    
    private func toggleScanning() {
        guard receiver.centralManager.state == .poweredOn else {
            return
        }

        if receiver.isScanning {
            receiver.stopScanning()
        } else {
            receiver.startScanning()
        }
    }
}
