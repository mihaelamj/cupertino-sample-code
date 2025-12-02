/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that simulates the generation of heart rate and heart beat data, and which provides this data
 to its delegate.
*/

import HealthKit

protocol GameControllerHeartSensorSessionDelegate: AnyObject {
    func sessionDidStart(_ session: GameControllerHeartSensorSession, startDate: Date)
    func sessionDidReceiveHeartRate(_ session: GameControllerHeartSensorSession, heartRate: HKQuantity, dateInterval: DateInterval)
    func sessionDidReceiveHeartBeat(_ session: GameControllerHeartSensorSession, timeIntervalSinceStart: TimeInterval, precededByGap: Bool)
    func sessionDidEnd(_ session: GameControllerHeartSensorSession, endDate: Date)
}

class GameControllerHeartSensorSession {
    let UUID = NSUUID()
    let startDate = Date()
    let device = HKDevice(name: "Heart Rate Game Controller",
                          manufacturer: "Heart Rate Game Controller Manufacturer",
                          model: "1.0",
                          hardwareVersion: "1.0",
                          firmwareVersion: "1.0",
                          softwareVersion: "1.0",
                          localIdentifier: nil,
                          udiDeviceIdentifier: nil)

    weak var delegate: GameControllerHeartSensorSessionDelegate?
    private var endDate: Date?
    
    init(delegate: GameControllerHeartSensorSessionDelegate) {
        self.delegate = delegate
    }
    
    func start() {
        delegate?.sessionDidStart(self, startDate: self.startDate)
    }
    
    func finish() {
        let endDate = Date()
        generateSimulatedHeartData(endDate)
        delegate?.sessionDidEnd(self, endDate: endDate)
        self.endDate = endDate
    }
    
    private func generateSimulatedHeartData(_ endDate: Date) {

        // Generate heart rate data.
        let numberOfHeartRates = Int(CFAbsoluteTimeGetCurrent() - startDate.timeIntervalSinceReferenceDate) + Int.random(in: 1...3)
        let interval = (endDate.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate) / Double(numberOfHeartRates + 1)
        let BPMUnit = HKUnit(from: "count/min")
        
        var quantityDate = startDate.addingTimeInterval(interval)
        var quantityValue = Int.random(in: 60...120)
        
        for _ in 0..<numberOfHeartRates {
            let heartRateQuantity = HKQuantity(unit: BPMUnit, doubleValue: Double(quantityValue))
            delegate?.sessionDidReceiveHeartRate(self, heartRate: heartRateQuantity, dateInterval: DateInterval(start: quantityDate, duration: 0))
            
            quantityDate = quantityDate.addingTimeInterval(interval)
            quantityValue += Int.random(in: -1...2)
        }
        
        // Generate heart beat series data.
        var timeSinceStart = 0.0
        for _ in 0..<10 {
            timeSinceStart += Double.random(in: 0.75...1.50)
            delegate?.sessionDidReceiveHeartBeat(self, timeIntervalSinceStart: timeSinceStart, precededByGap: false)
        }
    }
}
