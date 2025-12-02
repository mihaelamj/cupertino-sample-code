/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The server's Bluetooth peripheral manager.
*/

import CoreBluetooth
import os

class BTPeripheralManager: NSObject, ObservableObject, CBPeripheralManagerDelegate {
	let logger = Logger(subsystem: "com.example.apple-DataAccessDemo", category: "BTPeripheralManager")
	var manager: CBPeripheralManager!
	@Published var isSwitchedOn = false
	private var isAdvertising = false
	private let peripheralQueue = DispatchQueue(label: "com.apple.peripheral.main")
	let demoServiceUUID = CBUUID(string: "f347d5f2-181b-4e19-b601-a9dbffaef332")
	let deviceIdCharUUID = CBUUID(string: "161dc5a6-2c75-49f1-be08-7686a82cc754")
	private let value = "AD34E"

	private let kMaxAdvertisedNameLen = 8

	override init() {
		super.init()

		manager = CBPeripheralManager(delegate: self, queue: nil)
		manager.delegate = self
	}

	// MARK: Public
	public func startAdvertising() {
		if !isAdvertising && isSwitchedOn {
			let valueData = value.data(using: .utf8)
			let deviceUUID = getDeviceUniqueId()
			logger.log("ID Checker: Setting BT adv ID: \(deviceUUID)")
			let deviceIdData = deviceUUID.data(using: .utf8)

			let deviceIdChar = CBMutableCharacteristic(type: deviceIdCharUUID, properties: [.read], value: deviceIdData, permissions: [.readable])
			let myChar2 = CBMutableCharacteristic(type: CBUUID(nsuuid: UUID()), properties: [.read], value: valueData, permissions: [.readable])

			let myService = CBMutableService(type: demoServiceUUID, primary: true)

			myService.characteristics = [deviceIdChar, myChar2]

			manager.add(myService)

			let advertisementData = [
				CBAdvertisementDataLocalNameKey: getDeviceUniqueId().prefix(kMaxAdvertisedNameLen),
				CBAdvertisementDataServiceUUIDsKey: [demoServiceUUID]
			] as [String: Any]
			logger.log("ID Checker: BT Advertising Data: \(advertisementData)")
			manager.startAdvertising(advertisementData)
			isAdvertising = true
			logger.log("Started Advertising with name \(getDeviceUniqueId())")
		}
	}

	public func stopAdvertising(afterAdvertisingStopped:(() -> Void)? = nil) {
		if isAdvertising {
			logger.log("Stop Advertising BT")
			manager.stopAdvertising()
			isAdvertising = false
		}
	}

	// MARK: CBPeripheralManagerDelegate
	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		var statusMessage = ""

		switch peripheral.state {
		case .poweredOn:
			logger.log("Bluetooth Status: Turned On")
			statusMessage = "Bluetooth Status: Turned On"
			isSwitchedOn = true

		case .poweredOff:
			statusMessage = "Bluetooth Status: Turned Off"
			isSwitchedOn = false
		case .resetting:
			statusMessage = "Bluetooth Status: Resetting"
			isSwitchedOn = false
		case .unauthorized:
			statusMessage = "Bluetooth Status: Not Authorized"
			isSwitchedOn = false
		case .unsupported:
			statusMessage = "Bluetooth Status: Not Supported"
			isSwitchedOn = false
		default:
			statusMessage = "Bluetooth Status: Unknown"
			isSwitchedOn = false
		}
		logger.log("\(statusMessage)")
		if isAdvertising && !isSwitchedOn {
			stopAdvertising()
		}
	}

	func peripheralManager(_: CBPeripheralManager, willRestoreState: [String: Any]) {
		logger.log("willRestoreState")
	}

	func peripheralManager(_: CBPeripheralManager, didAdd: CBService, error: Error?) {
		logger.log("didAddService")
	}

	func peripheralManagerDidStartAdvertising(_: CBPeripheralManager, error: Error?) {
		if let error = error {
			isAdvertising = false
			logger.error("Couldn't start advertising: \(String(describing: error))")
			return
		}
		logger.log("DidStartAdvertising")
	}

	func peripheralManager(_: CBPeripheralManager, central: CBCentral, didSubscribeTo: CBCharacteristic) {
		logger.log("didSubscribeTo")
	}

	func peripheralManager(_: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom: CBCharacteristic) {
		logger.log("didUnsubscribeFrom")
	}

	func peripheralManagerIsReady(toUpdateSubscribers: CBPeripheralManager) {
		logger.log("toUpdateSubscribers")
	}

	func peripheralManager(_: CBPeripheralManager, didReceiveRead: CBATTRequest) {
		logger.log("didReceiveRead")
	}

	func peripheralManager(_: CBPeripheralManager, didReceiveWrite: [CBATTRequest]) {
		logger.log("didReceiveWrite")
	}

}
