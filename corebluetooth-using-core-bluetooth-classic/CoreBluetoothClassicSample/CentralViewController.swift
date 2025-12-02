/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to monitor bluetooth connections.
*/

import CoreBluetooth
import UIKit
import os.log

struct BTConstants {
	// These are sample GATT service strings. Your accessory will need to include these services/characteristics in its GATT database
    static let sampleServiceUUID = CBUUID(string: "AAAA")
    static let sampleCharacteristicUUID = CBUUID(string: "BBBB")
}

class CentralViewController: UIViewController {
    @IBOutlet internal var tableView: UITableView!
    private var cbManager: CBCentralManager!
    private var cbState = CBManagerState.unknown
    private var cbPeripherals = [CBPeripheral]()

    override func viewDidLoad() {
        super.viewDidLoad()
		tableView.dataSource = self
		tableView.reloadData()

        cbManager = CBCentralManager(delegate: self, queue: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard segue.identifier == "peripheralViewSegue",
			let destinationVc = segue.destination as? PeripheralViewController else { return }
		destinationVc.cbManager = cbManager

		guard let indexPath = tableView.indexPathForSelectedRow else { return }
		destinationVc.selectedPeripheral = cbPeripherals[indexPath.row]
    }
}

extension CentralViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return cbPeripherals.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "peripheralCell", for: indexPath)
		let index = cbPeripherals.count - (indexPath.row + 1)
		cell.textLabel?.text = "\(cbPeripherals[index].name ?? "CBPeripheral")"
		return cell
	}
}

extension CentralViewController: CBCentralManagerDelegate {
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
		// In your application, you would address each possible value of central.state and central.authorization
		switch central.state {
		case .resetting:
			os_log("Connection with the system service was momentarily lost. Update imminent")
		case .unsupported:
			os_log("Platform does not support the Bluetooth Low Energy Central/Client role")
		case .unauthorized:
			switch central.authorization {
			case .restricted:
				os_log("Bluetooth is restricted on this device")
			case .denied:
				os_log("The application is not authorized to use the Bluetooth Low Energy role")
			default:
				os_log("Something went wrong. Cleaning up cbManager")
			}
		case .poweredOff:
			os_log("Bluetooth is currently powered off")
		case .poweredOn:
			os_log("Starting cbManager")
			let matchingOptions = [CBConnectionEventMatchingOption.serviceUUIDs: [BTConstants.sampleServiceUUID]]
			cbManager.registerForConnectionEvents(options: matchingOptions)
		default:
			os_log("Cleaning up cbManager")
		}
	}

	func centralManager(_ central: CBCentralManager, connectionEventDidOccur event: CBConnectionEvent, for peripheral: CBPeripheral) {
		os_log("connectionEventDidOccur for peripheral: %@", peripheral)
		switch event {
		case .peerConnected:
			cbPeripherals.append(peripheral)
		case .peerDisconnected:
			os_log("Peer %@ disconnected!", peripheral)
		default:
			if let idx = cbPeripherals.firstIndex(where: { $0 === peripheral }) {
				cbPeripherals.remove(at: idx)
			}
		}
		tableView.reloadData()
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		os_log("peripheral: %@ connected", peripheral)
	}

	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		os_log("peripheral: %@ failed to connect", peripheral)
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		os_log("peripheral: %@ disconnected", peripheral)
	}
}

