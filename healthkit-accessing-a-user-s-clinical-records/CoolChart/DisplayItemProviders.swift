/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol for decoding the FHIR resources and determining what to display for each category.
*/

import HealthKit
import UIKit
import ModelsDSTU2
import ModelsR4

protocol DisplayItemProvider {
    func displayItem(for sample: HKSample) -> DisplayItem
    
    func detailViewController(for sample: HKSample) -> UIViewController?
}

extension DisplayItemProvider {
    func detailViewController(for sample: HKSample) -> UIViewController? {
        return nil
    }
}

protocol FitnessDisplayItemProvider: DisplayItemProvider {
    var dateFormatter: DateFormatter { get }
}

protocol DisplayItemSubtitleConvertible {
    var displayItemSubtitle: String { get }
}

struct ErrorDisplayItemProvider: DisplayItemProvider {
    func displayItem(for sample: HKSample) -> DisplayItem {
        return DisplayItem.errorItem
    }
}

enum FHIRResourceDecodingError: Error {
    case notAnHKClinicalRecord(HKSample)
    case noFHIRResourcePresent(HKClinicalRecord)
    case resourceTypeNotSupported(HKFHIRResourceType)
    case versionNotSupported(String)
}

struct ClinicalDisplayItemProvider: DisplayItemProvider {
    
    func displayItem(for sample: HKSample) -> DisplayItem {
        do {
            return try displayItemInternal(for: sample)
        } catch {
            print("Failed to retrieve a DisplayItem from \(sample): \(error)")
            return DisplayItem.errorItem
        }
    }
    
    func displayItemInternal(for sample: HKSample) throws -> DisplayItem {
        guard let clinicalRecord = sample as? HKClinicalRecord else {
            throw FHIRResourceDecodingError.notAnHKClinicalRecord(sample)
        }
        guard let fhirResource = clinicalRecord.fhirResource else {
            throw FHIRResourceDecodingError.noFHIRResourcePresent(clinicalRecord)
        }
        
        do {
            let item = try displayItemConvertible(for: fhirResource)
            return DisplayItem(title: clinicalRecord.displayName, subtitle: item.displayItemSubtitle, accessory: .disclosure)
        } catch {
            return DisplayItem(title: clinicalRecord.displayName, subtitle: error.localizedDescription, accessory: .none)
        }
    }
    
    func displayItemConvertible(for resource: HKFHIRResource) throws -> DisplayItemSubtitleConvertible {
        do {
            return try decode(resource: resource)
        } catch {
            print("Failed to decode \(resource.resourceType) using FHIRModels: \(error)")
            return try decodePartial(resource: resource)
        }
    }
    
    /// Each clincal record retrieved from HealthKit is associated with a FHIR Resource. Decode it using the FHIRModels.
    func decode(resource: HKFHIRResource) throws -> DisplayItemSubtitleConvertible {
        if #available(iOS 14.0, *) {
            switch resource.fhirVersion.fhirRelease {
            case .dstu2:
                return try decodeDSTU2(resource: resource)
            case .r4:
                return try decodeR4(resource: resource)
            default:
                throw FHIRResourceDecodingError.versionNotSupported(resource.fhirVersion.stringRepresentation)
            }
        } else {
            return try decodeDSTU2(resource: resource) // On iOS 12 and 13, HealthKit always uses DSTU2 encoding for FHIR resources.
        }
    }
    
    /// Decode FHIR resources using ModelsDSTU2
    func decodeDSTU2(resource: HKFHIRResource) throws -> DisplayItemSubtitleConvertible {
        let decoder = JSONDecoder()
        
        switch resource.resourceType {
        case .allergyIntolerance:
            return try decoder.decode(ModelsDSTU2.AllergyIntolerance.self, from: resource.data)
        case .condition:
            return try decoder.decode(ModelsDSTU2.Condition.self, from: resource.data)
        case .immunization:
            return try decoder.decode(ModelsDSTU2.Immunization.self, from: resource.data)
        case .medicationDispense:
            return try decoder.decode(ModelsDSTU2.MedicationDispense.self, from: resource.data)
        case .medicationOrder:
            return try decoder.decode(ModelsDSTU2.MedicationOrder.self, from: resource.data)
        case .medicationStatement:
            return try decoder.decode(ModelsDSTU2.MedicationStatement.self, from: resource.data)
        case .observation:
            return try decoder.decode(ModelsDSTU2.Observation.self, from: resource.data)
        case .procedure:
            return try decoder.decode(ModelsDSTU2.Procedure.self, from: resource.data)
        default:
            throw FHIRResourceDecodingError.resourceTypeNotSupported(resource.resourceType)
        }
    }

    /// Decode FHIR resources using the ModelsR4 encoding.
    @available(iOS 14.0, *)
    func decodeR4(resource: HKFHIRResource) throws -> DisplayItemSubtitleConvertible {
        let decoder = JSONDecoder()
        
        switch resource.resourceType {
        case .allergyIntolerance:
            return try decoder.decode(ModelsR4.AllergyIntolerance.self, from: resource.data)
        case .condition:
            return try decoder.decode(ModelsR4.Condition.self, from: resource.data)
        case .immunization:
            return try decoder.decode(ModelsR4.Immunization.self, from: resource.data)
        case .medicationDispense:
            return try decoder.decode(ModelsR4.MedicationDispense.self, from: resource.data)
        case .medicationRequest:
            return try decoder.decode(ModelsR4.MedicationRequest.self, from: resource.data)
        case .medicationStatement:
            return try decoder.decode(ModelsR4.MedicationStatement.self, from: resource.data)
        case .observation:
            return try decoder.decode(ModelsR4.Observation.self, from: resource.data)
        case .procedure:
            return try decoder.decode(ModelsR4.Procedure.self, from: resource.data)
        default:
            throw FHIRResourceDecodingError.resourceTypeNotSupported(resource.resourceType)
        }
    }
    
    /// Provide a fallback in case the FHIR resource aren't 100% valid FHIR.
    /// Use Swift Codable for partial resource decoding, as defined in
    // PartialFHIRResources.swift.
    func decodePartial(resource: HKFHIRResource) throws -> DisplayItemSubtitleConvertible {
        func decode<T: DisplayItemSubtitleConvertible & Codable>(as type: T.Type) throws -> DisplayItemSubtitleConvertible {
            let decoder = JSONDecoder()
            return try decoder.decode(type.self, from: resource.data)
        }
        
        switch resource.resourceType {
        case .allergyIntolerance:
            return try decode(as: AllergyIntolerancePartial.self)
        case .condition:
            return try decode(as: ConditionPartial.self)
        case .immunization:
            return try decode(as: ImmunizationPartial.self)
        case .medicationDispense:
            return try decode(as: MedicationDispensePartial.self)
        case .medicationOrder:
            return try decode(as: MedicationOrderPartial.self)
        case .medicationStatement:
            return try decode(as: MedicationStatementPartial.self)
        case .observation:
            return try decode(as: ObservationPartial.self)
        case .procedure:
            return try decode(as: ProcedurePartial.self)
        default:
            throw FHIRResourceDecodingError.resourceTypeNotSupported(resource.resourceType)
        }
    }

    func detailViewController(for sample: HKSample) -> UIViewController? {
        guard let clinicalRecord = sample as? HKClinicalRecord, let fhirResource = clinicalRecord.fhirResource else {
            return nil
        }
        
        return FHIRSourceViewController(fhirResource: fhirResource)
    }
}

/// Create a separate display item for the walking and running distance data type.
struct DistanceDisplayItemProvider: FitnessDisplayItemProvider {
    let dateFormatter: DateFormatter = createDefaultDateFormatter()
    
    func displayItem(for sample: HKSample) -> DisplayItem {
        let stepType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        guard let quantitySample = sample as? HKQuantitySample, quantitySample.sampleType == stepType else {
            return DisplayItem.errorItem
        }
        
        let meters = Int(quantitySample.quantity.doubleValue(for: HKUnit.meter()))
        return DisplayItem(title: "\(meters) m", subtitle: dateFormatter.string(from: quantitySample.startDate))
    }
}

/// Create a separate display item for the step count.
struct StepsDisplayItemProvider: FitnessDisplayItemProvider {
    let dateFormatter: DateFormatter = createDefaultDateFormatter()
    
    func displayItem(for sample: HKSample) -> DisplayItem {
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        guard let quantitySample = sample as? HKQuantitySample, quantitySample.sampleType == stepType else {
            return DisplayItem.errorItem
        }
        
        let steps = Int(quantitySample.quantity.doubleValue(for: HKUnit.count()))
        return DisplayItem(title: "\(steps) Steps", subtitle: dateFormatter.string(from: quantitySample.startDate))
    }
}
