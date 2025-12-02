/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities to discover devices.
*/

import Foundation
import CoreBluetooth
import DeviceDiscoveryExtension
import Network
import os
import UniformTypeIdentifiers

class DeviceDiscovery: NSObject, CBCentralManagerDelegate {
	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "DeviceDiscovery")
	var eventHandler: DDEventHandler?
	var centralManager: CBCentralManager!
	var bluetoothScanning: Bool = false
	var browser: NWBrowser!
	var bonjourScanning: Bool = false
	// An artificial Bluetooth service UUID.
	let demoServiceUUID = CBUUID(string: "f347d5f2-181b-4e19-b601-a9dbffaef332")
	let deviceIdCharUUID = CBUUID(string: "161dc5a6-2c75-49f1-be08-7686a82cc754")

	let btOnlyProtocolType = UTType("com.example.apple-DataAccessDemo.Ant")!

	let sharedDeviceIdLength = 8
	let validProtocols = ["Ladybug", "Bolt"]
	var btTimeoutTickTimer: Timer?
    // A tick period in seconds.
	let btTimeoutTickPeriod = 1.0
    // A timeout count for one tick per second.
	let kBTScanningTimeoutCount = 4

	struct DeviceState {
		var device: DDDevice
		var btTimeoutCount = 0
	}

    // A dictionary of discovered devices. The key is the device identifier.
	var foundDDDevices: [String: DeviceState] = [:]

	let ddDeviceQueue = DispatchQueue(label: "discovery.queue")
	let centralManagerQueue = DispatchQueue(label: "centralManager.concurrent.queue", attributes: .concurrent)
	let defaultName = "New Demo Device"

	override init() {
		logger.log("Init")
		super.init()

		let parameters = NWParameters()
		parameters.includePeerToPeer = true
		browser = NWBrowser(for: .bonjourWithTXTRecord(type: "_deviceaccess._udp.", domain: nil), using: parameters)
		centralManager = CBCentralManager(delegate: self, queue: centralManagerQueue, options: [:])
	}

	func activate() {
		logger.log("Activate start")
		bluetoothStartScanning()
		bonjourStartScanning()
		logger.log("Activate end")
	}

	func invalidate() {
		logger.log("Invalidating")
		eventHandler = nil
		foundDDDevices = [:]
		bluetoothStopScanning()
		bonjourStopScanning()
		logger.log("Invalidated")
	}

	// MARK: Bluetooth
    
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		switch central.state {
		case .poweredOn:
			logger.log("Bluetooth Central Manager Status: Powered On")
			bluetoothStartScanning()
		case .poweredOff:
			logger.log("Bluetooth Central Manager Status: Powered Off")
		case .resetting:
			logger.log("Bluetooth Central Manager Status: Resetting")
		case .unauthorized:
			logger.log("Bluetooth Central Manager Status: Unauthorized")
		case .unsupported:
			logger.log("Bluetooth Central Manager Status:Unsupported")
		default:
			logger.log("Bluetooth Central Manager Status: Unknown")
		}
	}

	private func findBonjourMatch(forDeviceId matchID: String) -> DDDevice? {
		var result: DDDevice?
		ddDeviceQueue.sync {
			if let found = foundDDDevices[matchID] {
				result = found.device
			}
		}
		return result
	}

	private func updateFoundDevice(_ device: DDDevice, btTimeoutCount timeout: Int) {
		ddDeviceQueue.sync {
			foundDDDevices[device.identifier] = DeviceState(device: device, btTimeoutCount: timeout)
		}
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
	                    advertisementData: [String: Any], rssi RSSI: NSNumber) {
		var knownBTDevice = false
		ddDeviceQueue.sync {
			if var ddDevice = foundDDDevices.first(where: { $0.value.device.bluetoothIdentifier == peripheral.identifier }) {
				knownBTDevice = true
				ddDevice.value.btTimeoutCount = 0
				foundDDDevices.updateValue(ddDevice.value, forKey: ddDevice.key)
			}
		}
		guard !knownBTDevice else {
			return
		}

		guard let handler = eventHandler else {
			logger.log("Ignoring BT device \(peripheral): Can't report DDDevice events yet")
			return
		}

		guard let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String else {
			let name: String = peripheral.name ?? ""
			logger.debug("Ignoring CBPeripheral '\(peripheral)' advertisement '\(name)': NO ID (CBAdvertisementDataLocalNameKey)")
			return
		}

		let matchID = String(localName.prefix(sharedDeviceIdLength))
		if let bonjourDeviceMatch = findBonjourMatch(forDeviceId: matchID) {
			logger.log("ID Checker: Match found for BT device ID unchanged: \(bonjourDeviceMatch.identifier)")
			bonjourDeviceMatch.bluetoothIdentifier = peripheral.identifier
			updateFoundDevice(bonjourDeviceMatch, btTimeoutCount: 0)
			handler(DDDeviceEvent(eventType: .deviceChanged, device: bonjourDeviceMatch))

		} else {
			logger.log("ID Checker: Setting BT only device ID: \(matchID)")
			var name = peripheral.name ?? defaultName
			if name.isEmpty || name == matchID {
				name = defaultName
			}
			let ddDevice = DDDevice(displayName: "\(name) (\(matchID))", category: .hifiSpeaker, protocolType: btOnlyProtocolType, identifier: matchID)
			ddDevice.bluetoothIdentifier = peripheral.identifier
			updateFoundDevice(ddDevice, btTimeoutCount: 0)
			logger.log(".deviceFound CBPeripheral '\(peripheral)' '\(matchID)' to DDDevice \(ddDevice)")
			handler(DDDeviceEvent(eventType: .deviceFound, device: ddDevice))
		}
		setupBTTimeoutTimer()
	}

	private func setupBTTimeoutTimer() {
		ddDeviceQueue.sync { [weak self] in
			guard let strongSelf = self else { return }
			guard strongSelf.btTimeoutTickTimer == nil else {
				logger.log("BT monitor already started")
				return
			}
			strongSelf.btTimeoutTickTimer = Timer(timeInterval: btTimeoutTickPeriod, repeats: true) { [weak self] _ in
				guard let strongSelf = self else { return }
				strongSelf.ddDeviceQueue.async {
					self?.serviceBTDeviceTimer()
				}
			}
		}

		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self else { return }

			if let timer = strongSelf.btTimeoutTickTimer {
				RunLoop.main.add(timer, forMode: .common)
				strongSelf.logger.log("BT monitor started")
			}
		}
	}

	func bluetoothStartScanning() {
		guard centralManager.state == .poweredOn else {
			logger.log("Can't start BT scanning, not .poweredOn")
			return
		}

		if !bluetoothScanning {
			logger.log("Starting BT Scan")
			centralManager.scanForPeripherals(withServices: [demoServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
			bluetoothScanning = true
		} else {
			logger.error("BT scanning already started")
		}
	}

	func bluetoothStopScanning() {
		if bluetoothScanning {
			logger.log("Stopping BT Scan")
			centralManager.stopScan()
			bluetoothScanning = false
		}
	}

	// MARK: Bonjour
	func bonjourStartScanning() {
		if !bonjourScanning {
			bonjourScanning = true
			browser.stateUpdateHandler = { [weak self] newState in
				self?.bonjourStateUpdateHandler(newState)
			}

			browser.browseResultsChangedHandler = { [weak self] results, changes in
				self?.bonjourResultsChanged(results: results, changes: changes)
			}

			browser.start(queue: ddDeviceQueue)
		} else {
			logger.log("Bonjour already scanning")
		}
	}

	func bonjourStopScanning() {
		if bonjourScanning {
			bonjourScanning = false
			browser.cancel()
		}
	}

	func bonjourStateUpdateHandler(_ newState: NWBrowser.State) {
		logger.log("browser.stateUpdateHandler \(String(describing: newState))")
		switch newState {
		case .failed(let error):
			logger.log("Bonjour browsing failed error='\(error.localizedDescription)', cancelling...")
			bonjourStopScanning()
		default:
			break
		}
		if newState != .ready {
			self.foundDDDevices = self.clearBonjourDevices(from: self.foundDDDevices)
		}
	}
	func bonjourResultsChanged(results: Set<NWBrowser.Result>, changes: Set<NWBrowser.Result.Change>) {
		guard eventHandler != nil else {
			logger.error("Ignoring Bonjour results: no event handler to report set")
			return
		}
		var currentBonjourDevices: [String: DeviceState] = [:]
		var lostBonjourDevices: [String: DeviceState] = [:]
		var changedNewDevices: [NWBrowser.Result] = []
		for change in changes {
			switch change {
			case .added(let deviceAdded):
				// Find a matching already found DDDevice (BJ or BJ+BT) or create a new one (BJ only)
				// a new Bonjour-only device.
				if let ddDeviceState = bonjourDidDiscover(deviceAdded) {
					currentBonjourDevices[ddDeviceState.device.identifier] = ddDeviceState
				}
			case .removed(let deviceRemoved):
				if let knownDevice = foundDDDevices.first(where: { $0.value.device.networkEndpoint == deviceRemoved.endpoint }) {
					logger.log("Known device removed: \(String(describing: knownDevice))")
					lostBonjourDevices[knownDevice.key] = knownDevice.value
				}
			case .changed(let oldDevice, let newDevice, let deviceFlags):
				if let knownDevice = foundDDDevices.first(where: { $0.value.device.networkEndpoint == oldDevice.endpoint }) {
					logger.log(
                        """
                        Known device changed: \(String(describing: knownDevice)) to
                        \(String(describing: knownDevice)) flags: \(String(describing: deviceFlags))
                        """
                    )
					lostBonjourDevices[knownDevice.key] = knownDevice.value
					changedNewDevices.append(newDevice)
				} else if let ddDeviceState = bonjourDidDiscover(newDevice) {
					// This could happen when an ignored device refreshes its metadata.
					currentBonjourDevices[ddDeviceState.device.identifier] = ddDeviceState
				} else {
					logger.log(
                        """
                        Ignoring untracked device change: \(String(describing: oldDevice)) to
                        \(String(describing: newDevice)) flags: \(String(describing: deviceFlags))
                        """
                    )
				}
			default:
				logger.log("Bonjour device not changed: \(String(describing: change))")
			}
		}
		// Report Bonjour devices as lost and the remaining Bluetooth devices as changed.
		if !lostBonjourDevices.isEmpty {
			foundDDDevices = clearBonjourDevices(from: lostBonjourDevices)
		}

		for newDevice in changedNewDevices {
			if let ddDeviceState = bonjourDidDiscover(newDevice) {
				logger.log("Device changed was re-added: \(String(describing: ddDeviceState))")
				currentBonjourDevices[ddDeviceState.device.identifier] = ddDeviceState
			}
		}

		// Complete the full set of found devices by adding in the Bonjour search results.
		foundDDDevices.merge(currentBonjourDevices) { (_, new) in new }
	}

	// Notifies the app of a newly discovered device. This function reports the new device or
    // updates a Bonjour or Bluetooth group with the new device and returns a reference to it.
	private func bonjourDidDiscover(_ result: NWBrowser.Result) -> DeviceState? {
		dispatchPrecondition(condition: .onQueue(ddDeviceQueue))

		if let existingDevice = foundDDDevices.first(where: { $0.value.device.networkEndpoint == result.endpoint }) {
			logger.log("Bonjour device has known network endpoint: \(String(describing: result))")
			return existingDevice.value
		}

		var ddTXTRecord: NWTXTRecord?

		switch result.metadata {
		case .bonjour(let txtRecord):
			logger.log("BONJOUR METADATA \(txtRecord.dictionary)")
			ddTXTRecord = txtRecord
		case .none:
			logger.log("NO METADATA")
		default:
			logger.log("DEFAULT METADATA")
		}

		guard let txtRecord = ddTXTRecord?.dictionary else {
			logger.log("Ignoring result '\(String(describing: result))' due empty txt record")
			return nil
		}

		guard let fullDeviceIdentifier = txtRecord["ID"] else {
			logger.log("Ignoring result '\(String(describing: result))' due empty identifier")
			return nil
		}
		let deviceIdentifier = String(fullDeviceIdentifier.prefix(sharedDeviceIdLength))

		guard let deviceName = txtRecord["NAME"] else {
			logger.log("Ignoring result '\(String(describing: result))' due empty name")
			return nil
		}

		guard let targetProtocol = txtRecord["PROTO"] else {
			logger.log("Ignoring result '\(String(describing: result))', can't find target protocol")
			return nil
		}

		guard validProtocols.contains(targetProtocol) else {
			logger.log("Ignoring result '\(String(describing: result))' due missing/invalid protocol: '\(targetProtocol)'")
			return nil
		}

		guard let protocolType = UTType("com.example.apple-DataAccessDemo." + targetProtocol) else {
			logger.log("Ignoring result '\(String(describing: result))' due unknown protocol UTType: '\(targetProtocol)'")
			return nil
		}

		let ddDevice = DDDevice(displayName: "\(deviceName) (\(deviceIdentifier))",
                                category: .tvWithMediaBox, protocolType: protocolType, identifier: deviceIdentifier)

		logger.log("ID Checker: Setting Bonjour only device ID: \(deviceIdentifier)")
		ddDevice.networkEndpoint = result.endpoint
		ddDevice.txtRecord = ddTXTRecord
		var ddEvent = DDDeviceEvent(eventType: .deviceFound, device: ddDevice)

		var currentBtTimeoutCount = 0
		if let ddMatch = foundDDDevices[deviceIdentifier], ddMatch.device.bluetoothIdentifier != nil {
			
            // The extension finds an existing Bluetooth device.
            // Update it with the prior device identifier.
			logger.log("ID Checker: Match found for Bonjour setting device ID: \(deviceIdentifier)")
			ddDevice.bluetoothIdentifier = ddMatch.device.bluetoothIdentifier
			currentBtTimeoutCount = ddMatch.btTimeoutCount
			ddEvent = DDDeviceEvent(eventType: .deviceChanged, device: ddDevice)
		}
		let updatedDevice = DeviceState(device: ddDevice, btTimeoutCount: currentBtTimeoutCount)

		logger.log("Bonjour \(ddEvent.eventType == .deviceFound ? "new" : "BT match") device found: \(String(describing: result)), \(ddEvent)")
		if let handler = eventHandler {
			handler(ddEvent)
		}

		return updatedDevice
	}

	private func clearBonjourDevices(from targetDevices: [String: DeviceState]) -> [String: DeviceState] {
		dispatchPrecondition(condition: .onQueue(ddDeviceQueue))

		guard !targetDevices.isEmpty else {
			logger.warning("clearBonjourDevices targetDevices set is empty")
			return targetDevices
		}

		// The extension loses a Bonjour device.
		let bonjourOnlyDevices = targetDevices.filter({ $0.value.device.networkEndpoint != nil && $0.value.device.bluetoothIdentifier == nil })
		
        // Bluetooth and Bonjour devices change to Bluetooth-only devices.
		let btChangedDevices = targetDevices.filter({ $0.value.device.networkEndpoint != nil && $0.value.device.bluetoothIdentifier != nil })
		
        // Gather all the devices that remain Bluetooth devices.
		let resultDevices = targetDevices.filter({ $0.value.device.bluetoothIdentifier != nil })

		guard let handler = eventHandler else {
			logger.log("no event handler to report lost Bonjour devices")
			return resultDevices
		}

		for item in bonjourOnlyDevices {
			let ddDevice = item.value.device
			logger.log("Reporting Bonjour Lost: Name: \(ddDevice.displayName) ID: \(ddDevice.identifier)")
			let ddEvent = DDDeviceEvent(eventType: .deviceLost, device: ddDevice)
			handler(ddEvent)
		}

		for item in btChangedDevices {
			let ddDevice = item.value.device
			logger.log("Reporting .deviceChanged BT only: \(ddDevice.displayName)")
			ddDevice.networkEndpoint = nil
			ddDevice.txtRecord = nil
			ddDevice.protocolType = UTType("com.example.apple-DataAccessDemo.Ant")!
			let ddEvent = DDDeviceEvent(eventType: .deviceChanged, device: ddDevice)
			handler(ddEvent)
		}
		return resultDevices
	}

	private func serviceBTDeviceTimer() {
		dispatchPrecondition(condition: .onQueue(ddDeviceQueue))
		logger.log("serviceBTDeviceTimer")

		let btDevices = foundDDDevices.filter({ $0.value.device.bluetoothIdentifier != nil })
		var lostBTDevices: [DDDevice] = []
		for item in btDevices {
			let ddDevice = item.value.device
			let timeoutCount = item.value.btTimeoutCount + 1
			if timeoutCount >= kBTScanningTimeoutCount {
				lostBTDevices.append(ddDevice)
			} else {
				foundDDDevices[ddDevice.identifier] = DeviceState(device: ddDevice, btTimeoutCount: timeoutCount)
			}
		}

		for ddDevice in lostBTDevices where ddDevice.networkEndpoint == nil {
			
            // Keep the device if it has a network endpoint.
			foundDDDevices.removeValue(forKey: ddDevice.identifier)
		}

		let remainingBTDevices = foundDDDevices.filter({ $0.value.device.bluetoothIdentifier != nil })
		if remainingBTDevices.isEmpty {
			btTimeoutTickTimer?.invalidate()
			btTimeoutTickTimer = nil
			logger.log("BT monitor stopped")
		}

		guard let handler = eventHandler else {
			logger.log("no event handler to report lost BT devices")
			return
		}
		for ddDevice in lostBTDevices {
			if ddDevice.networkEndpoint == nil {
				logger.log("Reporting BT Lost: Name: \(ddDevice.displayName) ID: \(ddDevice.identifier)")
				handler(DDDeviceEvent(eventType: .deviceLost, device: ddDevice))
			} else {
				ddDevice.bluetoothIdentifier = nil
				logger.log("Reporting BT+Bonjor -> Bonjour .deviceChanged: Name: \(ddDevice.displayName) ID: \(ddDevice.identifier)")
				handler(DDDeviceEvent(eventType: .deviceChanged, device: ddDevice))
			}
		}

	}
}
