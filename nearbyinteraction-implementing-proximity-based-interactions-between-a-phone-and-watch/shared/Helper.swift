/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of properties that are used throughout the project.
*/

import Foundation

enum Helper {
    
    /// A key that is used for transferring discovery tokens between devices.
    static let discoveryTokenKey: String = "discovery-token"
    
    /// A formatter that converts a distance to a string with units.
    static var localFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.alwaysShowsDecimalSeparator = true
        formatter.numberFormatter.roundingMode = .ceiling
        formatter.numberFormatter.maximumFractionDigits = 1
        formatter.numberFormatter.minimumFractionDigits = 1
        return formatter
    }()
    
    /// The unit length for the device's current locale.
    static var localUnits: UnitLength {
        Locale.current.usesMetricSystem ? .meters : .feet
    }
}
