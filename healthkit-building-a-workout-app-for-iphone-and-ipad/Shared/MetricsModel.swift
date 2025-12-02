/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure that wraps the data you use to update the views.
*/

import Foundation

struct MetricsModel {
    var elapsedTime: TimeInterval
    var heartRate: Double?
    var activeEnergy: Double?
    var distance: Double?
    var speed: Double?
    
    var supportsDistance: Bool = false
    var supportsSpeed: Bool = false
}

extension MetricsModel: Codable, Hashable, Equatable {
    
    func getHeartRate() -> String {
        guard let heartRateValue = heartRate else {
            return "--"
        }
            return heartRateValue.formatted(.number.precision(.fractionLength(0)))
    }
    
    func getActiveEnergy() -> String {
        guard let activeEnergyValue = activeEnergy else {
            return "--"
        }
        return Measurement(
            value: activeEnergyValue,
            unit: UnitEnergy.kilocalories
        ).formatted(
            .measurement(
                width: .abbreviated,
                usage: .workout,
                numberFormatStyle: .number.precision(.fractionLength(0))
            )
        )
    }
    
    func getDistance() -> String {
        guard let distanceValue = distance else {
            return "--"
        }
        return Measurement(
            value: distanceValue,
            unit: UnitLength.meters
        ).formatted(
            .measurement(
                width: .abbreviated,
                usage: .road
            )
        )
    }
    
    func getSpeed() -> String {
        guard let speedValue = speed else {
            return "--"
        }
        return Measurement(
            value: speedValue,
            unit: UnitSpeed.metersPerSecond)
        .converted(to: UnitSpeed.milesPerHour)
        .formatted(.measurement(width: .abbreviated))
    }
}
