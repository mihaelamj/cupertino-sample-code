/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The reminder sort order enumeration.
*/

import Foundation

enum ReminderSortValue: String, Identifiable, CaseIterable, Sendable {
    case creationDate
    case dueDate
    case title
    
    var id: Self { self }
}

extension ReminderSortValue {
    var title: String {
        switch self {
        case .creationDate: "Creation Date"
        case .dueDate: "Due Date"
        default:
            self.rawValue.capitalized
        }
    }
    
    var systemImage: String {
        switch self {
        case .creationDate: "calendar"
        case .dueDate: "clock"
        case .title: "textformat"
        }
    }
}
