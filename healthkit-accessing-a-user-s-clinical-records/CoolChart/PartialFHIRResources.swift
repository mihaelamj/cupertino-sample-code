/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Determine what to display for the subtitle of each item in the category view.
*/

import Foundation

struct Coding: Codable {
    var code: String
    var display: String?
    var system: String
    var version: String?
}

struct CodeableConcept: Codable {
    var coding: [Coding]
    var text: String?
}

struct AllergyIntolerancePartial: Codable {
    var category: String?
    var substance: CodeableConcept
}

struct ConditionPartial: Codable {
    var category: CodeableConcept
    var code: CodeableConcept
    var clinicalStatus: String
    var verificationStatus: String
}

struct ImmunizationPartial: Codable {
    var reported: Bool
    var status: String
    var vaccineCode: CodeableConcept
    var wasNotGiven: Bool
}

struct MedicationDispensePartial: Codable {
    struct DosageInstruction: Codable {
        var method: CodeableConcept
        var route: CodeableConcept
    }
    
    var dosageInstruction: [DosageInstruction]
    var medicationCodeableConcept: CodeableConcept
}

struct MedicationOrderPartial: Codable {
    var medicationCodeableConcept: CodeableConcept
    var status: String
}

struct MedicationStatementPartial: Codable {
    var medicationCodeableConcept: CodeableConcept
    var status: String
}

struct ObservationPartial: Codable {
    var category: CodeableConcept
    var code: CodeableConcept
    var status: String
}

struct ProcedurePartial: Codable {
    var code: CodeableConcept
    var status: String
}
