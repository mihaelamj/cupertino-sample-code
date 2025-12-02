/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that determine the subtitle for each item in the category view.
*/

import ModelsDSTU2
import ModelsR4
import UIKit

// MARK: - DSTU2
extension ModelsDSTU2.AllergyIntolerance: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.category?.value?.rawValue ?? "unknown"
    }
}

extension ModelsDSTU2.Condition: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.clinicalStatus?.value?.string ?? "unknown"
    }
}

extension ModelsDSTU2.Immunization: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status.value?.rawValue ?? "unknown"
    }
}

extension ModelsDSTU2.MedicationDispense: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.dosageInstruction?.first?.method?.text?.value?.string ?? "Dispensed"
    }
}

extension ModelsDSTU2.MedicationOrder: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status?.value?.rawValue ?? "unknown"
    }
}

extension ModelsDSTU2.MedicationStatement: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status.value?.rawValue ?? "unknown"
    }
}

extension ModelsDSTU2.Observation: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status.value?.rawValue ?? "unknown"
    }
}

extension ModelsDSTU2.Procedure: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status.value?.rawValue ?? "unknown"
    }
}

// MARK: - R4
extension ModelsR4.AllergyIntolerance: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.category?.first?.value?.rawValue ?? "unknown"
    }
}

extension ModelsR4.Condition: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.clinicalStatus?.coding?.first?.code?.value?.string ?? "unknown"
    }
}

extension ModelsR4.Immunization: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status.value?.rawValue ?? "unknown"
    }
}

extension ModelsR4.MedicationDispense: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.dosageInstruction?.first?.method?.text?.value?.string ?? "Dispensed"
    }
}

extension ModelsR4.MedicationRequest: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status.value?.rawValue ?? "unknown"
    }
}

extension ModelsR4.MedicationStatement: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status.value?.rawValue ?? "unknown"
    }
}

extension ModelsR4.Observation: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status.value?.rawValue ?? "unknown"
    }
}

extension ModelsR4.Procedure: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status.value?.rawValue ?? "unknown"
    }
}
