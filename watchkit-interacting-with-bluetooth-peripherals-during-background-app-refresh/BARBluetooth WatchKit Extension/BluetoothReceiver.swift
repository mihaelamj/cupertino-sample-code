/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class for connecting to a Bluetooth peripheral and reading its characteristic values.
*/

import CoreBluetooth
import os.log

protocol BluetoothReceiverDelegate: AnyObject {
    func didReceiveData(_ message: Data) -> Int
    func didCompleteDisconnection(from peripheral: CBPeripheral, mustDisconnect: Bool)
    func didFailWithError(_ error: BluetoothReceiverError)
}

enum BluetoothReceiverError: Error {
    case failedToConnect
    case failedToDiscoverCharacteristics
    case failedToDiscoverServices
    case failedToReceiveCharacteristicUpdate
}

/// A listener to subscribe to a Bluetooth LE peripheral and get characteristic updates from it.
///
class BluetoothReceiver: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var logger = Logger(
        subsystem: BARBluetoothApp.name,
        category: String(describing: BluetoothReceiver.self)
    )
    
    var notificationHandler = ExtensionDelegate.instance.notificationHandler

    weak var delegate: BluetoothReceiverDelegate? = nil
    
    var centralManager: CBCentralManager!
    
    private var serviceUUID: CBUUID!
    
    private var characteristicUUID: CBUUID!
    
    @Published private(set) var connectedPeripheral: CBPeripheral? = nil
    
    private(set) var knownDisconnectedPeripheral: CBPeripheral? = nil
    
    @Published private(set) var isScanning: Bool = false
    
    var scanToAlert = false
    
    var mustDisconnect = false
    
    @Published var discoveredPeripherals = Set<CBPeripheral>()
    
    init(service: CBUUID, characteristic: CBUUID) {
        super.init()
        self.serviceUUID = service
        self.characteristicUUID = characteristic
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        logger.info("scanning for new peripherals with service \(self.serviceUUID)")
        
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
        
        discoveredPeripherals.removeAll()
        isScanning = true
    }
    
    func stopScanning() {
        logger.info("stopped scanning for new peripherals")
        centralManager.stopScan()
        isScanning = false
    }
    
    func connect(to peripheral: CBPeripheral) {
        if let connectedPeripheral = connectedPeripheral {
            disconnect(from: connectedPeripheral, mustDisconnect: true)
        }
        
        logger.info("connecting to \(peripheral.name ?? "unnamed peripheral")")
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect(from peripheral: CBPeripheral, mustDisconnect: Bool) {
        logger.info("disconnecting from \(peripheral.name ?? "unnamed peripheral")")
        self.mustDisconnect = mustDisconnect
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        let state = central.state
        logger.log("central state is: \(state.rawValue)")
        
        if state == .poweredOn {
            startScanning()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber ) {
        if scanToAlert {
            if #available(watchOS 9, *) {
                logger.info("sending notification from advertising")
                let alertValue = 99
                notificationHandler!.requestUserNotification(temperature: Measurement(value: Double(alertValue), unit: UnitTemperature.celsius))
                UserDefaults.standard.setValue(alertValue, forKey: BluetoothConstants.receivedDataKey)
                ComplicationController.updateAllActiveComplications()
            }
        } else if peripheral != connectedPeripheral, !discoveredPeripherals.contains(peripheral) {
                logger.info("discovered \(peripheral.name ?? "unnamed peripheral")")
                discoveredPeripherals.insert(peripheral)
                peripheral.delegate = self
            }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("failed to connect to \(peripheral.name ?? "unnamed peripheral")")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("connected to \(peripheral.name ?? "unnamed peripheral")")
        discoveredPeripherals.remove(peripheral)
        connectedPeripheral = peripheral
        knownDisconnectedPeripheral = nil
        peripheral.discoverServices([BluetoothConstants.sampleServiceUUID])
    }
    
    /// If the app wakes up to handle a background refresh task, the system calls this method if
    /// a peripheral disconnects when the app transitions to the background.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("disconnected from \(peripheral.name ?? "unnamed peripheral")")
        connectedPeripheral = nil
        
        /// Keep track of the last known peripheral.
        knownDisconnectedPeripheral = peripheral
        
        delegate?.didCompleteDisconnection(from: peripheral, mustDisconnect: self.mustDisconnect)
        self.mustDisconnect = false
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logger.error("error discovering service: \(error.localizedDescription)")
            delegate?.didFailWithError(.failedToDiscoverServices)
            return
        }
        
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            logger.info("no valid services on \(peripheral.name ?? "unnamed peripheral")")
            delegate?.didFailWithError(.failedToDiscoverServices)
            return
        }
        
        logger.info("discovered service \(service.uuid) on \(peripheral.name ?? "unnamed peripheral")")
        peripheral.discoverCharacteristics([characteristicUUID], for: service)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        if invalidatedServices.contains(where: { $0.uuid == serviceUUID }) {
            logger.info("\(peripheral.name ?? "unnamed peripheral") did invalidate service \(self.serviceUUID)")
            disconnect(from: peripheral, mustDisconnect: true)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error? ) {
        if let error = error {
            logger.error("error discovering characteristic: \(error.localizedDescription)")
            delegate?.didFailWithError(.failedToDiscoverCharacteristics)
            return
        }
        
        guard let characteristics = service.characteristics, !characteristics.isEmpty else {
            logger.info("no characteristics discovered on \(peripheral.name ?? "unnamed peripheral") for service \(service.description)")
            delegate?.didFailWithError(.failedToDiscoverCharacteristics)
            return
        }
        
        if let characteristic = characteristics.first(where: { $0.uuid == characteristicUUID }) {
            logger.info("discovered characteristic \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
            peripheral.readValue(for: characteristic) /// Immediately read the characteristic's value.
        
            if #available(watchOS 9.0, *) {
                /// Subscribe to the characteristic.
                peripheral.setNotifyValue(true, for: characteristic)
                logger.info("setNotifyValue for \(characteristic.uuid) on \(peripheral.name ?? "unnamed peripheral")")
            }

        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            logger.error("\(peripheral.name ?? "unnamed peripheral") failed to update value: \(error!.localizedDescription)")
            delegate?.didFailWithError(.failedToReceiveCharacteristicUpdate)
            return
        }
        
        guard let data = characteristic.value else {
            logger.warning("characteristic value from \(peripheral.name ?? "unnamed peripheral") is nil")
            delegate?.didFailWithError(.failedToReceiveCharacteristicUpdate)
            return
        }
        
        logger.info("\(peripheral.name ?? "unnamed peripheral") did update characteristic: \(data)")
        let value = delegate?.didReceiveData(data) ?? -1
        
        if #available(watchOS 9, *) {
            if value > BluetoothConstants.normalTemperatureLimit {
                logger.info("sending notification from characteristic")
                notificationHandler!.requestUserNotification(temperature: Measurement(value: Double(value), unit: UnitTemperature.celsius))
            }
        }
    }
}
