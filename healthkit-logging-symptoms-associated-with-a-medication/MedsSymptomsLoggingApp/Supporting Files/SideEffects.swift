/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A dictionary that maps a medication's RxNorm code to `SymptomModel`.
*/

import HealthKit

struct SideEffects {
    static let rxNormSystem = "http://www.nlm.nih.gov/research/umls/rxnorm"

    static let sideEffectsByRxNormCode: [String: Set<SymptomModel>] = [
        // Acetaminophen 500 mg Oral Capsule
        "198439": [SymptomModel(name: "Nausea", categoryID: .nausea),
                   SymptomModel(name: "Headache", categoryID: .headache),
                   SymptomModel(name: "Dizziness", categoryID: .dizziness)],

        // Carbinoxamine Maleate Biphasic Release Oral Capsule (10 mg)
        "1012918": [SymptomModel(name: "Constipation", categoryID: .constipation),
                    SymptomModel(name: "Nausea", categoryID: .nausea),
                    SymptomModel(name: "Dizziness", categoryID: .dizziness)],

        // Ciprofloxacin Injection 200 mg/20 mL
        "1665229": [SymptomModel(name: "Headache", categoryID: .headache),
                    SymptomModel(name: "Diarrhea", categoryID: .diarrhea),
                    SymptomModel(name: "Nausea", categoryID: .nausea),
                    SymptomModel(name: "Body Ache", categoryID: .generalizedBodyAche)]
    ]

    /// Returns a list of `SymptomModel` instances associated with the provided medication.
    static func symptoms(for medication: AnnotatedMedicationConcept) -> [SymptomModel] {
        var symptoms: [SymptomModel] = []
        /// Filter out codings that don't have the RxNorm system.
        let rxNormCodes = medication.relatedCodings
            .filter { $0.system == Self.rxNormSystem }
            .map { $0.code }

        for rxNormCode in rxNormCodes {
            /// Performs a lookup of `SymptomModel` instances for the provided `RxNormCode`.
            if let fetchedSymptoms = SideEffects.sideEffectsByRxNormCode[rxNormCode] {
                for symptom in fetchedSymptoms {
                    symptoms.append(symptom)
                }
            }
        }

        return symptoms
    }
}
