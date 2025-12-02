/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example device-discovery extension.
*/

import DeviceDiscoveryExtension
import ExtensionFoundation
import Foundation
import os

@main
final class DataAccessDemoExtension: DDDiscoveryExtension {
	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "Appex")
	private var _deviceDiscovery:	DeviceDiscovery?
	private var _deviceSession: DDDiscoverySession?

	// Responds when the system starts discovery.
	func startDiscovery(session: DDDiscoverySession) {
		logger.log("Start DD DEMO discovery")
		if let deviceDiscovery = _deviceDiscovery { deviceDiscovery.invalidate() }

    let deviceDiscovery = DeviceDiscovery()

		_deviceDiscovery = deviceDiscovery
		_deviceSession = session

		deviceDiscovery.eventHandler = { event in
			if deviceDiscovery != self._deviceDiscovery { return }
			self.logger.log("Event: \(event)")
			print("Event: \(event)")
			switch event.eventType {
			case .deviceFound, .deviceLost, .deviceChanged:
				self._deviceSession?.report(event)
			default:
				break
			}
		}
		deviceDiscovery.activate()
	}

    // Responds when the system stops discovery.
	func stopDiscovery(session: DDDiscoverySession) {
		logger.log("Stop DD DEMO discovery")
		if let deviceDiscovery = _deviceDiscovery { deviceDiscovery.invalidate() }
	}
}
