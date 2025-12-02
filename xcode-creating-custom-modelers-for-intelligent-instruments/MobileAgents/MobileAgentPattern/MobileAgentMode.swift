/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Mobile Agent Mode determines which mode the Mobile Agent is in to decide which functions or logic to execute at the current stop.
*/
import Foundation

extension MobileAgent {
    enum Mode: Equatable {
        
        case retrieveGoatList
        case displayGoatList
        case addGoat
        case commitGoatList
        case sortGoatList
        case activating
        case finished
        case failed

        var identifier: String {
            switch self {
            case .activating: return "Activating"
            case .finished: return "Finished"
            case .failed: return "Failed"
            case .retrieveGoatList: return "Retrieve Goat List"
            case .displayGoatList: return "Display Goat List"
            case .addGoat: return "Add Goat"
            case .commitGoatList: return "Commit Goat List"
            case .sortGoatList: return "Sort Goat List"
            }
        }
    }
}
