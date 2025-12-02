/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that provides formatted strings for workout metrics.
*/

import Foundation
import HealthKit

// MARK: - Workout statistics
//
extension HKWorkout {
    var totalTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? ""
    }
    
    var averageCyclingSpeed: String {
        var value: Double = 0
        if let statistics = statistics(for: HKQuantityType(.cyclingSpeed)),
           let average = statistics.averageQuantity() {
            value = average.doubleValue(for: HKUnit.mile().unitDivided(by: HKUnit.hour()))
        }
        let measurement = Measurement(value: value, unit: UnitSpeed.milesPerHour)
        let numberStyle = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
        return measurement.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: numberStyle))
    }

    var averageCyclingPower: String {
        var value: Double = 0
        if let statistics = statistics(for: HKQuantityType(.cyclingPower)),
           let average = statistics.averageQuantity() {
            value = average.doubleValue(for: .watt())
        }
        let measurement = Measurement(value: value, unit: UnitPower.watts)
        let numberStyle = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
        return measurement.formatted(.measurement(width: .abbreviated, usage: .asProvided, numberFormatStyle: numberStyle))
    }

    var averageCyclingCadence: String {
        var value: Double = 0
        let cadenceUnit = HKUnit.count().unitDivided(by: .minute())
        if let statistics = statistics(for: HKQuantityType(.cyclingCadence)),
           let average = statistics.averageQuantity() {
            value = average.doubleValue(for: cadenceUnit)
        }
        return value.formatted(.number.precision(.fractionLength(0))) + " rpm"
    }
    
    var totalCyclingDistance: String {
        var value: Double = 0
        if let statistics = statistics(for: HKQuantityType(.distanceCycling)),
           let sum = statistics.sumQuantity() {
            value = sum.doubleValue(for: .meter())
        }
        let measurement = Measurement(value: value, unit: UnitLength.meters)
        let numberStyle: FloatingPointFormatStyle<Double> = .number.precision(.fractionLength(2))
        return measurement.formatted(.measurement(width: .abbreviated, usage: .road, numberFormatStyle: numberStyle))
    }
    
    var totalEnergy: String {
        var value: Double = 0
        if let statistics = statistics(for: HKQuantityType(.activeEnergyBurned)),
           let sum = statistics.sumQuantity() {
            value = sum.doubleValue(for: .kilocalorie())
        }
        let measurement = Measurement(value: value, unit: UnitEnergy.kilocalories)
        let numberStyle = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(0))
        return measurement.formatted(.measurement(width: .abbreviated, usage: .workout, numberFormatStyle: numberStyle))
    }
    
    var averageHeartRate: String {
        var value: Double = 0
        if let statistics = statistics(for: HKQuantityType(.heartRate)),
           let average = statistics.averageQuantity() {
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            value = average.doubleValue(for: heartRateUnit)
        }
        return value.formatted(.number.precision(.fractionLength(0))) + " bpm"
    }
}
