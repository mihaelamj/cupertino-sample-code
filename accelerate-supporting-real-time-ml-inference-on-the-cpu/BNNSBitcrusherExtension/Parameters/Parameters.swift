/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher parameters file.
*/

import Foundation
import AudioToolbox

let BNNSBitcrusherExtensionParameterSpecs = ParameterTreeSpec {
    ParameterGroupSpec(identifier: "global", name: "Global") {
        // Bitcrusher resolution.
        ParameterSpec(
            address: .resolution,
            identifier: "resolution",
            name: "Resolution",
            units: .generic,
            valueRange: 1 ... 100,
            defaultValue: 50
        )
        
        // Saturation gain.
        ParameterSpec(
            address: .saturationGain,
            identifier: "saturationGain",
            name: "Saturation Gain",
            units: .generic,
            valueRange: 0.1 ... 10,
            defaultValue: 1
        )
        
        ParameterSpec(
            address: .mix,
            identifier: "mix",
            name: "Dry / Wet",
            units: .generic,
            valueRange: 0 ... 1,
            defaultValue: 0.5
        )
    }
}

extension ParameterSpec {
    init(
        address: BNNSBitcrusherExtensionParameterAddress,
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
