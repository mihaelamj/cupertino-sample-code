/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The priority model.
*/

import Foundation

enum Priority: Int, Identifiable, CaseIterable {
    case none = 0
    case low = 9
    case medium = 5
    case high = 1
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .none: "None"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }
}

extension Priority {
    static func matching(_ reminderPriority: Int) -> Priority {
        switch reminderPriority {
        case 0: .none
        case 1...4: .high
        case 5: .medium
        case 6...9: .low
        default: fatalError("Unknown error")
        }
    }
}
