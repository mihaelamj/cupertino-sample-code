/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Properties and behaviors specific to Kilgo services.
*/

import HomeKit

extension HMService {
    
    /// The service types that Kilgo garage doors support.
    enum KilgoServiceType {
        case lightBulb, garageDoor, unknown
    }
    
    /// The Kilgo service type for this service.
    var kilgoServiceType: KilgoServiceType {
        switch serviceType {
        case HMServiceTypeLightbulb: return .lightBulb
        case HMServiceTypeGarageDoorOpener: return .garageDoor
        default: return .unknown
        }
    }
    
    /// The primary characteristic type to be controlled, given the service type.
    var primaryControlCharacteristicType: String? {
        switch kilgoServiceType {
        case .lightBulb: return HMCharacteristicTypePowerState
        case .garageDoor: return HMCharacteristicTypeTargetDoorState
        case .unknown: return nil
        }
    }

    /// The primary characteristic controlled by tapping the accessory cell in the accessory list.
    var primaryControlCharacteristic: HMCharacteristic? {
        return characteristics.first { $0.characteristicType == primaryControlCharacteristicType }
    }

    /// The primary characteristic type to be displayed, given the service type.
    var primaryDisplayCharacteristicType: String? {
        switch kilgoServiceType {
        case .lightBulb: return HMCharacteristicTypePowerState
        case .garageDoor: return HMCharacteristicTypeCurrentDoorState
        case .unknown: return nil
        }
    }
    
    /// The primary characteristic visible in the accessory cell in the accessory list.
    var primaryDisplayCharacteristic: HMCharacteristic? {
        return characteristics.first { $0.characteristicType == primaryDisplayCharacteristicType }
    }
    
    /// The custom displayable characteristic types specific to Kilgo devices.
    enum KilgoCharacteristicTypes: String {
        case fadeRate = "7E536242-341C-4862-BE90-272CE15BD633"
    }

    /// The list of characteristics to display in the UI.
    var displayableCharacteristics: [HMCharacteristic] {
        let characteristicTypes = [HMCharacteristicTypePowerState,
                                   HMCharacteristicTypeBrightness,
                                   HMCharacteristicTypeHue,
                                   HMCharacteristicTypeSaturation,
                                   HMCharacteristicTypeTargetDoorState,
                                   HMCharacteristicTypeCurrentDoorState,
                                   HMCharacteristicTypeObstructionDetected,
                                   HMCharacteristicTypeTargetLockMechanismState,
                                   HMCharacteristicTypeCurrentLockMechanismState,
                                   KilgoCharacteristicTypes.fadeRate.rawValue]
        
        return characteristics.filter { characteristicTypes.contains($0.characteristicType) }
    }

    /// A graphical representation of the service, given its current state.
    var icon: UIImage? {
        let (_, icon) = stateAndIcon
        return icon
    }
    
    /// A textual representation of the current state of the service.
    var state: String {
        let (state, _) = stateAndIcon
        return state
    }
    
    /// A tuple containing a string and icon representing the current state of the service.
    private var stateAndIcon: (String, UIImage?) {
        switch kilgoServiceType {
        case .garageDoor:
            if let value = primaryDisplayCharacteristic?.value as? Int,
                let doorState = HMCharacteristicValueDoorState(rawValue: value) {
                switch doorState {
                case .open: return ("Open", #imageLiteral(resourceName: "door-open"))
                case .closed: return ("Closed", #imageLiteral(resourceName: "door-closed"))
                case .opening: return ("Opening", #imageLiteral(resourceName: "door-opening"))
                case .closing: return ("Closing", #imageLiteral(resourceName: "door-closing"))
                case .stopped: return ("Stopped", #imageLiteral(resourceName: "door-closed"))
                @unknown default: return ("Unknown", nil)
                }
            } else {
                return ("Unknown", #imageLiteral(resourceName: "door-closed"))
            }
        case .lightBulb:
            if let value = primaryDisplayCharacteristic?.value as? Bool {
                if value {
                    return ("On", #imageLiteral(resourceName: "bulb-on"))
                } else {
                    return ("Off", #imageLiteral(resourceName: "bulb-off"))
                }
            } else {
                return ("Unknown", #imageLiteral(resourceName: "bulb-off"))
            }
        case .unknown:
            return ("Unknown", nil)
        }
    }
}
