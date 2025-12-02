/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The proximity model.
*/

import EventKit

enum Proximity: Int, Identifiable, CaseIterable {
    case none = 0
    case arriving
    case leaving
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .none: "None"
        case .arriving: "Arriving"
        case .leaving: "Leaving"
        }
    }
}

extension Proximity {
    var alarmProximity: EKAlarmProximity {
        switch self {
        case .none: return .none
        case .arriving: return .enter
        case .leaving: return .leave
        }
    }
    
    static func matching(_ proximity: EKAlarmProximity) -> Proximity {
        switch proximity {
        case .none: return .none
        case .enter: return .arriving
        case .leave: return .leaving
        @unknown default:
            fatalError("Unknown error")
        }
    }
}
