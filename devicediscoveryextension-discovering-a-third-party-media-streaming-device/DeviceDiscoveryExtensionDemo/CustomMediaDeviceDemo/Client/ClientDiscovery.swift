/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities for Bluetooth client discovery and connectivity.
*/

import Foundation
import SwiftUI
import CoreBluetooth
import os

struct ClientDiscoveryView: View {
	@ObservedObject var clientDiscovery: ClientDiscovery

	init() {
		clientDiscovery = ClientDiscovery()
	}

	var body: some View {
		if clientDiscovery.bluetoothScanning {
			List(clientDiscovery.scannedBLEDevices, id: \.self) { peripheral in
				Text(verbatim: peripheral.name ?? "Default")
			}
		}
	}
}

class ClientDiscovery: NSObject, CBCentralManagerDelegate, ObservableObject {
	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "ClientDiscovery")

	var centralManager: CBCentralManager!
	@Published var bluetoothScanning: Bool = false
	@Published var scannedBLEDevices: [CBPeripheral] = []

	var timer = Timer()
	let btTimeout: TimeInterval = 10

	let centralManagerQueue = DispatchQueue(label: "centralManager.concurrent.queue", attributes: .concurrent)

	// Set a real UUID for the Bluetooth service. The sample app defines a hard-coded UUID.
	let demoServiceUUID = CBUUID(string: "f347d5f2-181b-4e19-b601-a9dbffaef332")

	func activate() {
		logger.log("Starting Discovery")
		centralManager = CBCentralManager(delegate: self, queue: centralManagerQueue)

		scannedBLEDevices = []
		timer = Timer.scheduledTimer(withTimeInterval: btTimeout, repeats: true, block: { _ in
			self.bluetoothStopScanning()
			self.bluetoothStartScanning()
		})
	}

	func invalidate() {
		logger.log("Stopping Discovery")
		scannedBLEDevices = []
		bluetoothStopScanning()
		timer.invalidate()
	}

	// MARK: Bluetooth
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		var statusMessage = ""

		switch central.state {
		case .poweredOn:
			logger.log("Bluetooth Central Manager Status: Turned On")
			statusMessage = "Bluetooth Central Manager Status: Turned On"
			bluetoothStartScanning()
		case .poweredOff:
			statusMessage = "Bluetooth Central Manager Status: Turned Off"
		case .resetting:
			statusMessage = "Bluetooth Central Manager Status: Resetting"
		case .unauthorized:
			statusMessage = "Bluetooth Central Manager Status: Not Authorized"
		case .unsupported:
			statusMessage = "Bluetooth Central Manager Status: Not Supported"
		default:
			statusMessage = "Bluetooth Central Manager Status: Unknown"
		}
		print(statusMessage)
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
	                    advertisementData: [String: Any], rssi RSSI: NSNumber) {
		logger.log("CBPeripheral: \(peripheral)")
		logger.log("CB Advertisement: \(advertisementData)")
		scannedBLEDevices.append(peripheral)
	}

	func bluetoothStartScanning() {
		if !bluetoothScanning {
			logger.log("Starting BT Scan")
			scannedBLEDevices = []
			centralManager.scanForPeripherals(withServices: [demoServiceUUID])
			bluetoothScanning = true
		}
	}

	func bluetoothStopScanning() {
		if bluetoothScanning {
			logger.log("Stopped BT Scan")
			centralManager.stopScan()
			bluetoothScanning = false
		}
	}
}
