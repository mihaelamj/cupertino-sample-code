/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The metadata structure for the activity attribues shared between the app and the widget extension.
*/

import AlarmKit

struct CookingData: AlarmMetadata {
    let createdAt: Date
    let method: Method?
    
    init(method: Method? = nil) {
        self.createdAt = Date.now
        self.method = method
    }
    
    enum Method: String, Codable {
        case stove
        case grill
        case oven
        case fry
        case chill
        
        var icon: String {
            switch self {
            case .stove: "stove"
            case .grill: "fire"
            case .oven: "oven"
            case .fry: "frying.pan"
            case .chill: "snowflake"
            }
        }
    }
}
