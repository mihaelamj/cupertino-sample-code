/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model to map HealthKit symptoms, such as nausea.
*/

import Foundation
import HealthKit

let symptomTypeIdentifiers: [HKCategoryTypeIdentifier] = [
    .nausea,
    .diarrhea,
    .headache,
    .dizziness,
    .generalizedBodyAche,
    .appetiteChanges
]

/// A `SymptomModel` represents a single symptom.
struct SymptomModel: Sendable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let categoryID: HKCategoryTypeIdentifier
}
