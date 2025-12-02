/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Properties and behaviors specific to Kilgo service characteristics.
*/

import HomeKit

extension HMCharacteristic {
    var stateNames: [String] {
        switch characteristicType {
        case HMCharacteristicTypeCurrentLockMechanismState: return ["Unsecured", "Secured", "Jammed", "Unknown"]
        case HMCharacteristicTypeTargetLockMechanismState: return ["Not Locked", "Locked"]
        case HMCharacteristicTypeCurrentDoorState: return ["Open", "Closed", "Opening", "Closing", "Stopped"]
        case HMCharacteristicTypeTargetDoorState: return ["Open", "Closed"]
        default: return []
        }
    }
    
    /// Indicates if you can write to the characteristic.
    var isWriteable: Bool {
        return properties.contains(HMCharacteristicPropertyWritable)
    }
    
    /// Indicates if you can read from the characteristic.
    var isReadable: Bool {
        return properties.contains(HMCharacteristicPropertyReadable)
    }
    
    /// Indicates if the characteristic is both readable and writable.
    var isReadWrite: Bool {
        return isReadable && isWriteable
    }
    
    /// Indicates that the characteristic value is a floating point number.
    var isFloat: Bool {
        return metadata?.format == HMCharacteristicMetadataFormatFloat
    }
    
    /// Indicates that the characteristic value is a signed integer.
    var isInt: Bool {
        return metadata?.format == HMCharacteristicMetadataFormatInt
    }
    
    /// Indicates that the characteristic value is an unsigned integer.
    var isUInt: Bool {
        return metadata?.format == HMCharacteristicMetadataFormatUInt8
            || metadata?.format == HMCharacteristicMetadataFormatUInt16
            || metadata?.format == HMCharacteristicMetadataFormatUInt32
            || metadata?.format == HMCharacteristicMetadataFormatUInt64
        
    }
    
    /// Indicates that the characteristic value is a number.
    var isNumeric: Bool {
        return isInt || isFloat || isUInt
    }
    
    /// Indicates that the characteristic value is a Boolean.
    var isBool: Bool {
        return metadata?.format == HMCharacteristicMetadataFormatBool
    }
    
    /// The difference between the characteristic’s maximum and minimum values.
    var span: Decimal {
        guard let max = metadata?.maximumValue?.decimalValue,
            let min = metadata?.minimumValue?.decimalValue  else {
                return 1.0
        }
        return max - min
    }
    
    /// The characteristic value as a float.
    var floatValue: Float? {
        return (value as? NSNumber)?.floatValue
    }
    
    /// The characteristic value as a decimal value.
    var decimalValue: Decimal? {
        return (value as? NSNumber)?.decimalValue
    }
    
    /// Returns the value that you get by mapping the given fraction
    /// to the characteristic's span, accounting for step size.
    func valueFor(fraction: Float) -> Decimal {
        let interval = metadata?.stepValue?.decimalValue ?? 1.0
        var inVal = (Decimal(Double(fraction)) * span) / interval
        var outVal: Decimal = 0.0
        NSDecimalRound(&outVal, &inVal, 0, .plain)
        return outVal * interval
    }
    
    /// A name that best represents the characteristic in the UI.
    var displayName: String {
        return metadata?.manufacturerDescription ?? localizedDescription
    }
    
    /// A string that represents the characteristic’s value.
    var formattedValueString: String {
        guard
            let value = value,
            let metadata = metadata else { return "—" }
        
        // Use the metadata to drive the string formatting.
        switch metadata.format {
        case HMCharacteristicMetadataFormatString:
            return value as? String ?? "—"
            
        case HMCharacteristicMetadataFormatInt,
             HMCharacteristicMetadataFormatUInt8,
             HMCharacteristicMetadataFormatUInt16,
             HMCharacteristicMetadataFormatUInt32,
             HMCharacteristicMetadataFormatUInt64:
            guard let intValue = value as? Int else { return "—" }
            guard stateNames.isEmpty else { return stateNames[intValue] }
            return String(intValue)
            
        case HMCharacteristicMetadataFormatFloat:
            guard let floatValue = floatValue else { return "—" }
            return String(format: "%.1f", floatValue)
            
        case HMCharacteristicMetadataFormatBool:
            guard let boolValue = value as? Bool else { return "—" }
            return boolValue ? "YES" : "NO"
            
        default:
            return "—"
        }
    }
}
