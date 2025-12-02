/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities for various string manipulations.
*/

import HealthKit

/// Make any string even cooler.
func coolify(_ string: String) -> String {
    return "Cool \(string)"
}

/// Standardize the display of dates within the app.
func createDefaultDateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}

/// Used to unescape the FHIR JSON prior to displaying it in the FHIR Source view.
func unescapeJSONString(_ string: String) -> String {
    return string.replacingOccurrences(of: "\\/", with: "/").replacingOccurrences(of: "\\\\", with: "\\")
}

/// Differentiate between HKClinicalType and HKQuantityType data types for display purposes.
func categoryDisplayItemProvider(for sampleType: HKSampleType) -> DisplayItemProvider {
    if sampleType is HKClinicalType {
        return ClinicalDisplayItemProvider()
    }
    
    if let quantityType = sampleType as? HKQuantityType {
        switch HKQuantityTypeIdentifier(rawValue: quantityType.identifier) {
        case .distanceWalkingRunning:
            return DistanceDisplayItemProvider()
        case .stepCount:
            return StepsDisplayItemProvider()
        default:
            return ErrorDisplayItemProvider()
        }
    }
    
    return ErrorDisplayItemProvider()
}

/// Enable a display name for each HKSampleType.
extension HKSampleType {
    @objc var categoryDisplayName: String {
        return identifier
    }
}

/// Define the clinical data display names for each FHIR resource type.
extension HKClinicalType {
    @objc override var categoryDisplayName: String {
        switch HKClinicalTypeIdentifier(rawValue: identifier) {
        case .allergyRecord:
            return "Allergies"
        case .conditionRecord:
            return "Conditions"
        case .immunizationRecord:
            return "Immunizations"
        case .labResultRecord:
            return "Lab Results"
        case .medicationRecord:
            return "Medications"
        case .procedureRecord:
            return "Procedures"
        case .vitalSignRecord:
            return "Clinical Vitals"
        default:
            return super.categoryDisplayName
        }
    }
}

/// Define the HealthKit data display names for each sample type.
extension HKQuantityType {
    @objc override var categoryDisplayName: String {
        switch HKQuantityTypeIdentifier(rawValue: identifier) {
        case .distanceWalkingRunning:
            return "Walking + Running Distances"
        case .stepCount:
            return "Steps"
        default:
            return super.categoryDisplayName
        }
    }
}
