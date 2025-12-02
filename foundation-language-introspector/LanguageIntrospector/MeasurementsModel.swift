/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for measurements.
*/

import SwiftUI

@MainActor
@Observable class MeasurementsModel {
    var formatter: MeasurementFormatter
    var selectedUnitStyle: MeasurementFormatter.UnitStyle { didSet { updateFormatter() } }
    var providedUnit: Bool { didSet { updateFormatter() } }
    var naturalScale: Bool { didSet { updateFormatter() } }
    var temperatureWithoutUnit: Bool { didSet { updateFormatter() } }
    
    var localizedTemperature: String {
        string(from: Measurement<UnitTemperature>(value: 37, unit: .celsius))
    }
    
    var localizedSpeed: String {
        string(from: Measurement<UnitSpeed>(value: 100, unit: .kilometersPerHour))
    }
    
    var localizedArea: String {
        string(from: Measurement<UnitArea>(value: 1, unit: .acres))
    }
    
    init() {
        self.formatter = MeasurementFormatter()
        self.selectedUnitStyle = .medium
        self.providedUnit = false
        self.naturalScale = true
        self.temperatureWithoutUnit = false
        self.formatter.numberFormatter.maximumFractionDigits = 1
        self.updateFormatter()
    }
    
    func string<UnitType>(from measurement: Measurement<UnitType>) -> String where UnitType: Unit {
        return formatter.string(from: measurement)
    }
    
    private func updateFormatter() {
        formatter.unitStyle = selectedUnitStyle
        var options: MeasurementFormatter.UnitOptions = []
        if providedUnit { options.insert(.providedUnit) }
        if naturalScale { options.insert(.naturalScale) }
        if temperatureWithoutUnit { options.insert(.temperatureWithoutUnit) }
        formatter.unitOptions = options
    }
}
