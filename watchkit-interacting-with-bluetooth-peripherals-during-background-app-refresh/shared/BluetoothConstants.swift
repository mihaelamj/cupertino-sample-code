/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Bluetooth identifiers to use throughout the project.
*/

import CoreBluetooth

enum BluetoothConstants {
    
    /// An identifier for the sample service.
    static let sampleServiceUUID = CBUUID(string: "AAAA")
    
    /// An identifier for the sample characteristic.
    static let sampleCharacteristicUUID = CBUUID(string: "BBBB")

    /// The defaults key to use for persisting the most recently received data.
    static let receivedDataKey = "received-data"
    
    /// The maximum normal temperature, above which the app displays an alert.
    static let normalTemperatureLimit = 45
}
