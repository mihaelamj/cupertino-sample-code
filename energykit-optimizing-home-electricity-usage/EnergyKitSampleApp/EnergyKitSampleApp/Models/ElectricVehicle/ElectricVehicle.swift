/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model that represents an electric vehicle (EV).
*/

import Foundation

/// A data model that represents an EV.
struct ElectricVehicle {
    /// The EV state.
    var state: State
    /// The properties of the EV.
    var properties: Properties

    struct Properties {
        /// The desired state of charge at the end of the charging session.
        var desiredStateOfCharge: Double
        /// The current charging power, in kW.
        var chargingPower: Double
        /// The total capacity of the battery, in kWh.
        var batteryCapacity: Double
        /// The identifier of the EV.
        var vehicleID: String
    }

    struct State {
        /// A timestamp for the state.
        var timestamp: Date
        /// The amount of energy stored at the battery as a percentage relative to the battery capacity.
        var stateOfCharge: Double
        /// The power at which the EV is either charging or discharging, in kW.
        var powerLevel: Double
        /// The current summation of energy charged by the EV.
        var cumulativeEnergy: Double
        /// A Boolean value that indicates if the EV is charging.
        var isCharging: Bool
    }

    mutating func increaseChargeLevel(by value: Double) {
        state.stateOfCharge += value
    }

    // MARK: Setters

    mutating func setTimestamp(_ newValue: Date) {
        if state.timestamp != newValue {
            state.timestamp = newValue
        }
    }

    mutating func setStateOfCharge(_ newValue: Double) {
        if state.stateOfCharge != newValue {
            state.stateOfCharge = newValue
        }
    }

    mutating func setPowerLevel(_ newValue: Double) {
        if state.powerLevel != newValue {
            state.powerLevel = newValue
        }
    }

    mutating func setIsCharging(_ newValue: Bool) -> Bool {
        if state.isCharging != newValue {
            state.isCharging = newValue
            return true
        }
        return false
    }
}
