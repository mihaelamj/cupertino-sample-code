/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The step item model.
*/

import SwiftUI

enum StepItem: Int, Hashable {
    case first
    case second
    case completed
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .first: "Step 1"
        case .second: "Step 2"
        case .completed: "Process Completed"
        }
    }
    
    var secondaryText: LocalizedStringKey {
        switch self {
        case .first, .second: "Continue Process"
        case .completed: "Start Over"
        }
    }
    
    func next() -> StepItem? {
        switch self {
        case .first:
            return .second
        case .second:
            return .completed
        case .completed:
            return nil
        }
    }
}

extension StepItem: Identifiable {
    var id: Int { rawValue }
}
