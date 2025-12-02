/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model for mapping `HKMedicationDoseEvent`.
*/

import Foundation
import HealthKit

struct DoseEventModel: Sendable, Identifiable, Equatable, Hashable {
    var id: String
    var dateLogged: Date
    var status: HKMedicationDoseEvent.LogStatus

    /// The logged time of the dose event, formatted for display.
    var timeLoggedDisplayString: String {
        dateLogged.formatted(date: .omitted, time: .shortened)
    }

    /// The logged date of the dose event, formatted for display.
    var dateLoggedDisplayString: String {
        dateLogged.formatted(date: .abbreviated, time: .omitted)
    }
}

/// The status of a dose event.
extension HKMedicationDoseEvent.LogStatus {
    var description: String {
        switch self {
        case .taken: "Taken"
        case .skipped: "Skipped"
        default: "Unknown"
        }
    }
}
