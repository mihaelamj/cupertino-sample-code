/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The delegate manages the life cycle of the iOS app and responds to Bluetooth read requests.
*/

import UIKit
import CoreBluetooth

class ApplicationDelegate: NSObject, UIApplicationDelegate, BluetoothSenderDelegate {
    
    static private(set) var instance: ApplicationDelegate! = nil
    var bluetoothSender: BluetoothSender!
    
    var peripheralValue: Measurement<UnitTemperature> {
        /// Calculates a mock temperature value based on the current time of day.
        /// This is to slowly change the temperature as time passes, and not necesarily a meaningful calculation.
            let secondsPerDay: Int = 24 * 60 * 60
            let secondsToday = Int(Date().timeIntervalSince1970) % secondsPerDay
            let percent = Double(secondsToday) / Double(secondsPerDay)
            return Measurement(value: (20 + (percent * 10)), unit: UnitTemperature.celsius)
        }

    let characteristic = CBMutableCharacteristic(
        type: BluetoothConstants.sampleCharacteristicUUID,
        properties: [.read, .write, .notify],
        value: nil,
        permissions: [.readable, .writeable]
    )

    override init() {
        super.init()
        
        ApplicationDelegate.instance = self
        
        /// Initialize the Bluetooth sender with a service and a characteristic.
        let service = CBMutableService(type: BluetoothConstants.sampleServiceUUID, primary: true)
        service.characteristics = [characteristic]
        
        bluetoothSender = BluetoothSender(service: service)
        bluetoothSender.delegate = self
    }
    
    // MARK: BluetoothSenderDelegate
    
    /// Respond to a read request by sending a value for the characteristic.
    func getDataFor(requestCharacteristic: CBCharacteristic) -> Data? {
        if requestCharacteristic == characteristic {
            let data = Int(peripheralValue.value)
            return try? JSONEncoder().encode(data)
        } else {
            return nil
        }
    }
}
