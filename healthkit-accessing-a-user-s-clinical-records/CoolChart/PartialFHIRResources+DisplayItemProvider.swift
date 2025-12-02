/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Determine what to display for the subtitle of each item in the category view.
*/

import Foundation

extension AllergyIntolerancePartial: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.category ?? "unknown"
    }
}

extension ConditionPartial: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.clinicalStatus
    }
}

extension ImmunizationPartial: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status
    }
}

extension MedicationDispensePartial: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.dosageInstruction.first?.method.text ?? "Dispensed"
    }
}

extension MedicationOrderPartial: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status
    }
}

extension MedicationStatementPartial: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status
    }
}

extension ObservationPartial: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status
    }
}

extension ProcedurePartial: DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String {
        return self.status
    }
}
