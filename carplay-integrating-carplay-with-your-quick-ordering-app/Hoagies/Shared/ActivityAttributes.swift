/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods that manage attributes of the order status.
*/

import ActivityKit

struct OrderStatusAttributes: ActivityAttributes {
    
    public enum ContentStateValues: String {
        case isPickedUp = "pickedUp"
        case isReady = "ready"
        case isPreparing = "preparing"
        case isConfirmed = "confirmed"
        case unknown = ""
    }
    
    public struct ContentState: Codable, Hashable {
        var isPickedUp: Bool
        var isReady: Bool
        var isPreparing: Bool
        var isConfirmed: Bool
    }

    var hoagieOrder: TestHoagieData.HoagieOrder
    
    static func stateForValue(value: ContentStateValues?) -> ContentState {
        switch value {
        case .isPickedUp: return ContentState(isPickedUp: true, isReady: true, isPreparing: true, isConfirmed: true)
        case .isReady: return ContentState(isPickedUp: false, isReady: true, isPreparing: true, isConfirmed: true)
        case .isPreparing: return ContentState(isPickedUp: false, isReady: false, isPreparing: true, isConfirmed: true)
        case .isConfirmed: return ContentState(isPickedUp: false, isReady: false, isPreparing: false, isConfirmed: true)
        default: return ContentState(isPickedUp: false, isReady: false, isPreparing: false, isConfirmed: false)
        }
    }
    
    static func valueForState(value: OrderStatusAttributes.ContentState) -> OrderStatusAttributes.ContentStateValues {
        if value.isPickedUp {
            return ContentStateValues.isPickedUp
        } else if value.isReady {
            return ContentStateValues.isReady
        } else if value.isPreparing {
            return ContentStateValues.isPreparing
        } else if value.isConfirmed {
            return ContentStateValues.isConfirmed
        } else {
            return ContentStateValues.unknown
        }
    }
}
