/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data source for providing user-authorized `HKMedicationConcepts`.
*/

import Foundation
import SwiftUI
import HealthKit

extension HKUserAnnotatedMedication {
    /// Map a list of active medication concepts.
    var activeAnnotatedMedicationConcept: AnnotatedMedicationConcept {
        var name = medication.displayText
        if let nickname, !nickname.isEmpty {
            name = nickname
        }

        return AnnotatedMedicationConcept(conceptIdentifier: medication.identifier,
                                          name: name,
                                          relatedCodings: medication.relatedCodings,
                                          isArchived: false)
    }

    /// Map a list of archived medication concepts.
    var archivedAnnotatedMedicationConcept: AnnotatedMedicationConcept {
        var name = medication.displayText
            if let nickname, !nickname.isEmpty {
                name = nickname
        }

        return AnnotatedMedicationConcept(conceptIdentifier: medication.identifier,
                                          name: name,
                                          relatedCodings: medication.relatedCodings,
                                          isArchived: true)
    }
}

/// A class that provides access to the list of active and archived user-authorized medication concepts.
@Observable @MainActor class MedicationProvider {
    let healthStore = HealthStore.shared.healthStore
    var activeMedicationConcepts: [AnnotatedMedicationConcept] = []
    var archivedMedicationConcepts: [AnnotatedMedicationConcept] = []

    init() {
        Task {
            await loadDataFromHealthKit()
        }
    }

    /// Performs a query to HealthKit to retrieve the list of active and archived medication concepts.
    func loadDataFromHealthKit() async {
        do {
            /// Performs a query to HealthKit to retrieve the list of active and archived medication concepts.
            let annotatedMedicationConcepts = try await fetchMedications()
            activeMedicationConcepts = annotatedMedicationConcepts.filter { !$0.isArchived }.map { $0.activeAnnotatedMedicationConcept }
            archivedMedicationConcepts = annotatedMedicationConcepts.filter { $0.isArchived }.map { $0.archivedAnnotatedMedicationConcept }
        } catch {
            print("Unable to retrieve any user-annotated medications \(error)")
        }
    }

    /// Returns a list of user-authorized `HKUserAnnotatedMedication` objects.
    func fetchMedications() async throws -> [HKUserAnnotatedMedication] {
        /// Initialize the new query descriptor for fetching medications.
        let queryDescriptor = HKUserAnnotatedMedicationQueryDescriptor()

        /// The results are a list of `HKUserAnnotatedMedications`.
        /// If you supply a predicate or limit, the system returns only objects that match.
        return try await queryDescriptor.result(for: healthStore)
    }
}
