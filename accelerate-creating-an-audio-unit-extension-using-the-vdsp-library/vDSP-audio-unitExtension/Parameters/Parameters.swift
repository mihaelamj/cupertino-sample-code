/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit parameters file.
*/


import Foundation
import AudioToolbox

let vDSP_audio_unitExtensionParameterSpecs = ParameterTreeSpec {
    ParameterGroupSpec(identifier: "global", name: "Global") {
        
        ParameterSpec(
            address: .frequency,
            identifier: "frequency",
            name: "Frequency",
            units: .hertz,
            valueRange: 20 ... 20_000,
            defaultValue: 100.0
        )
        
        ParameterSpec(
            address: .Q,
            identifier: "Q",
            name: "Q",
            units: .generic,
            valueRange: 0.1 ... 25,
            defaultValue: 1
        )
        
        ParameterSpec(
            address: .dbGain,
            identifier: "dbGain",
            name: "Decibel Gain",
            units: .linearGain,
            valueRange: -50 ... 50,
            defaultValue: 15
        )
    }
}

extension ParameterSpec {
    init(
        address: vDSP_audio_unitExtensionParameterAddress,
        identifier: String,
        name: String,
        units: AudioUnitParameterUnit,
        valueRange: ClosedRange<AUValue>,
        defaultValue: AUValue,
        unitName: String? = nil,
        flags: AudioUnitParameterOptions = [AudioUnitParameterOptions.flag_IsWritable, AudioUnitParameterOptions.flag_IsReadable],
        valueStrings: [String]? = nil,
        dependentParameters: [NSNumber]? = nil
    ) {
        self.init(address: address.rawValue,
                  identifier: identifier,
                  name: name,
                  units: units,
                  valueRange: valueRange,
                  defaultValue: defaultValue,
                  unitName: unitName,
                  flags: flags,
                  valueStrings: valueStrings,
                  dependentParameters: dependentParameters)
    }
}
