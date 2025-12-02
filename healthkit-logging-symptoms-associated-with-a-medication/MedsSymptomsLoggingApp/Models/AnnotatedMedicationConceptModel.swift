/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model for mapping `HKMedicationConcept`.
*/

import Foundation
import HealthKit
import SwiftUI

struct AnnotatedMedicationConcept: Sendable, Identifiable, Hashable {
    var id: HKHealthConceptIdentifier {
        conceptIdentifier
    }
    
    var conceptIdentifier: HKHealthConceptIdentifier
    var name: String // nickname OR displayText
    var relatedCodings: Set<HKClinicalCoding>
    var isArchived: Bool
}
