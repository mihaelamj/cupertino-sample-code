/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to view details of a CBPeripheral.
*/

import CoreBluetooth
import UIKit
import os.log

class PeripheralViewController: UIViewController {
    @IBOutlet internal var pTableView: UITableView!
	var cbManager: CBCentralManager?
    var selectedPeripheral: CBPeripheral?

    private var peripheralInfo = [String]()
	private var peripheralConnectedState = false

    override func viewDidLoad() {
        super.viewDidLoad()
		pTableView.dataSource = self
        pTableView.reloadData()
        
        // Set peripheral delegate
        selectedPeripheral?.delegate = self
		cbManager?.delegate = self

		cbManager?.connect(selectedPeripheral!, options: nil)
    }
}

// MARK: - UITableViewDataSource
extension PeripheralViewController: UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return peripheralInfo.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "attributeCell", for: indexPath)
		let index = peripheralInfo.count - (indexPath.row + 1)
		cell.textLabel?.text = peripheralInfo[index]
		return cell
	}
}

extension PeripheralViewController: CBCentralManagerDelegate {
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		os_log("peripheral: %@ connected", peripheral)
        peripheralInfo.insert(peripheral.name ?? "CBPeripheral" + "connected", at: 0)
		pTableView.reloadData()

		peripheral.discoverServices([BTConstants.sampleServiceUUID])
	}

	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		os_log("peripheral: %@ failed to connect", peripheral)
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		os_log("peripheral: %@ disconnected", peripheral)
        peripheralInfo.insert(peripheral.name ?? "CBPeripheral" + "disconnected", at: 0)
		pTableView.reloadData()
		// Clean up cached peripheral state
	}
}

extension PeripheralViewController: CBPeripheralDelegate {
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let service = peripheral.services?.first else {
			if let error = error {
				os_log("Error discovering service: %@", "\(error)")
			}
			return
		}
		os_log("Discovered services %@", peripheral.services ?? [])
        peripheralInfo.insert("Service: " + service.uuid.uuidString, at: 0)
		pTableView.reloadData()

		peripheral.discoverCharacteristics([BTConstants.sampleCharacteristicUUID], for: service)
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard let characteristics = service.characteristics else {
			if let error = error {
				os_log("Error discovering characteristic: %@", "\(error)")
			}
			return
		}
		os_log("Discovered characteristics %@", characteristics)
        peripheralInfo.insert("Descriptors: " + characteristics.description, at: 0)
		pTableView.reloadData()

		peripheral.setNotifyValue(true, for: service.characteristics!.first!)
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let value = characteristic.value as NSData? else {
            os_log("Unable to determine the characteristic's value.")
            return
        }

        os_log("Value for peripheral %@ updated to: %@", peripheral, value)
        peripheralInfo.append("Sample value updated to: " + value.description)
        pTableView.reloadData()
	}

	func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
		// Accessory's GATT database has updated. Refresh your local cache (if any)
	}
}
