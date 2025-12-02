/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data source for providing `HKMedicationDoseEvent` samples for a provided `HKMedicationConcept`.
*/

import Foundation
import HealthKit

@Observable @MainActor class DoseEventProvider: Sendable {
    let healthStore: HKHealthStore
    /// The medication concept to fetch dose event samples for.
    let annotatedMedicationConcept: AnnotatedMedicationConcept?
    /// The most-recently logged dose.
    var lastDoseLogged: DoseEventModel?

    /// The list of dose event samples.
    private(set) var doseEvents: [DoseEventModel] = []

    private(set) var updatedDoseSampleCollection = [HKMedicationDoseEvent]()

    /// Creates a data source for providing `HKMedicationDoseEvent` samples for a provided `HKMedicationConcept`.
    init(healthStore: HKHealthStore,
         annotatedMedicationConcept: AnnotatedMedicationConcept) {
        self.healthStore = healthStore
        self.annotatedMedicationConcept = annotatedMedicationConcept

        Task {
            try await fetchAndObserveMostRecentDoseToday()
        }
    }

    /// Creates a data source for providing `HKMedicationDoseEvent` samples for a provided `HKMedicationConcept` over the provided interval.
    init(healthStore: HKHealthStore,
         annotatedMedicationConcept: AnnotatedMedicationConcept? = nil,
         dateInterval: DateInterval) {
        self.healthStore = healthStore
        self.annotatedMedicationConcept = annotatedMedicationConcept

        Task {
            try await beginObservingDoses(for: dateInterval)
        }
    }

    /// Returns the most-recently logged dose for the specified medication.
    /// This method demonstrates how to use a sample query to fetch dose event samples. The sample app doesn't use it.
    func todaysDose(for medication: HKMedicationConcept) async throws -> HKMedicationDoseEvent? {
        /// Returns the most-recently logged dose for the specified medication.
        let medicationPredicate = HKQuery.predicateForMedicationDoseEvent(medicationConceptIdentifier: medication.identifier)

        let now = Date.now
        let startOfDay = Calendar.current.startOfDay(for: now)
        /// Returns the most-recently logged dose for today.
        let loggedTodayPredicate = HKQuery.predicateForSamples(withStart: startOfDay,
                                                               end: nil,
                                                               options: [])

        /// Returns a predicate that matches medication dose events for today.
        let takenPredicate = HKQuery.predicateForMedicationDoseEvent(status: .taken)
        let sortDescriptors = [SortDescriptor(\HKSample.startDate, order: .reverse)]

        let predicate = NSCompoundPredicate(type: .and, subpredicates: [medicationPredicate, loggedTodayPredicate, takenPredicate])

        let samplePredicate = HKSamplePredicate.sample(type: .medicationDoseEventType(), predicate: predicate)

        /// Configure the query descriptor to fetch only the most-recent dose.
        let queryDescriptor = HKSampleQueryDescriptor(predicates: [samplePredicate],
                                                      sortDescriptors: sortDescriptors,
                                                      limit: 1)

        let results = try await queryDescriptor.result(for: healthStore)

        if let doseEvents = results as? [HKMedicationDoseEvent] {
            return doseEvents.first
        }

        return nil
    }

    /// Returns a predicate to fetch the most-recent dose event sample, and also configures the predicate with the provided `dateInterval`.
    func configureDoseEventAnchoredObjectQuery(dateInterval: DateInterval?) -> HKSamplePredicate<HKSample> {
        // Configure the query.
        var medicationPredicate = [NSPredicate]()

        if let conceptIdentifier = annotatedMedicationConcept?.conceptIdentifier as? HKHealthConceptIdentifier {
            medicationPredicate.append(HKQuery.predicateForMedicationDoseEvent(
                medicationConceptIdentifier: conceptIdentifier
            ))
        }

        /// Returns a predicate that matches the medication dose events for today.
        medicationPredicate.append(HKQuery.predicateForMedicationDoseEvent(status: .taken))

        if let dateInterval = dateInterval {
            medicationPredicate.append(HKQuery.predicateForSamples(withStart: dateInterval.start,
                                                                   end: dateInterval.end,
                                                                   options: [])
            )
        }

        let predicate = NSCompoundPredicate(type: .and, subpredicates: medicationPredicate)

        let samplePredicate = HKSamplePredicate.sample(type: .medicationDoseEventType(), predicate: predicate)

        return samplePredicate
    }

    /// Fetch and observe data if there's a provided date interval.
    /// Charts uses this method to query for logged doses in a specified chart date window.
    func beginObservingDoses(for dateInterval: DateInterval) async throws {
        let samplePredicate = configureDoseEventAnchoredObjectQuery(dateInterval: dateInterval)

        let anchoredObjectQuery = HKAnchoredObjectQueryDescriptor(predicates: [samplePredicate], anchor: nil)
        let sequence = anchoredObjectQuery.results(for: healthStore)

        for try await result in sequence {
            print("Received update to samples from HealthKit: \(result)")
            handleResult(result)
        }
    }

    /// Performs an initial fetch of the most-recent dose event sample.
    func fetchAndObserveMostRecentDoseToday() async throws {
        let now = Date.now
        let startOfDay = Calendar.current.startOfDay(for: now)
        let samplePredicate = configureDoseEventAnchoredObjectQuery(dateInterval: DateInterval(start: startOfDay, duration: 86_400))

        let anchoredObjectQuery = HKAnchoredObjectQueryDescriptor(predicates: [samplePredicate], anchor: nil)
        for try await result in anchoredObjectQuery.results(for: healthStore) {
            handleResultForLastLoggedDose(result)
        }
    }

    /// Performs an initial fetch of the most-recently logged dose event sample.
    func fetchAndObserveMostRecentDoseAllTime() async throws {
        let samplePredicate = configureDoseEventAnchoredObjectQuery(dateInterval: nil)

        let anchoredObjectQuery = HKAnchoredObjectQueryDescriptor(predicates: [samplePredicate], anchor: nil)
        for try await result in anchoredObjectQuery.results(for: healthStore) {
            handleResultForLastLoggedDose(result)
        }
    }

    /// Performs the necessary actions when receiving a result from the query.
    private func handleResultForLastLoggedDose(_ result: HKAnchoredObjectQueryDescriptor<HKSample>.Result) {
        let deletedSamples = result.deletedObjects

        /// Indicates whether someone deleted the existing sample.
        if deletedSamples.map({ $0.uuid }).contains(where: { $0.uuidString == lastDoseLogged?.id }) {
            print("Last dose sample was deleted")
        }

        /// Sort the results by their end date, and pick the most recent.
        let addedSamples = result.addedSamples.compactMap { $0 as? HKMedicationDoseEvent }.sorted(by: { $0.endDate < $1.endDate })
        guard let lastLoggedSample = addedSamples.last else {
            print("Unable to find a most-recent dose event sample.")
            return
        }

        /// If the most-recent sample's start date is after the most-recently logged dose's logged date, set it.
        if let dose = lastDoseLogged, lastLoggedSample.endDate <= dose.dateLogged {
            return
        }

        lastDoseLogged = DoseEventModel(id: lastLoggedSample.uuid.uuidString,
                                        dateLogged: lastLoggedSample.endDate,
                                        status: lastLoggedSample.logStatus)
    }

    private func handleResult(_ result: HKAnchoredObjectQueryDescriptor<HKSample>.Result) {
        guard let doseEvents = result.addedSamples as? [HKMedicationDoseEvent] else {
            /// Handle the failure.
            return
        }

        /// Clean up the deleted results.
        removeDoseEventSamples(with: result.deletedObjects)

        /// Update the chartable set of points with the added samples.
        updatedDoseSampleCollection.append(contentsOf: doseEvents)
    }

    /// Performs a cleanup of the `updatedDoseSampleCollection` with the `deletedObjects`.
    private func removeDoseEventSamples(with deletedObjects: [HKDeletedObject]) {
        updatedDoseSampleCollection.removeAll(where: { existingSample in
            deletedObjects.contains(where: { deletedObject in
                deletedObject.uuid == existingSample.uuid
            })
        })
    }

    /// Performs an update to the `updatedDoseSampleCollection` with the `addedSamples`.
    private func updateDoseEventSamples(with addedSamples: [HKMedicationDoseEvent]) {
        /// Someone deleted the observed sample.
        updatedDoseSampleCollection.append(contentsOf: addedSamples)
    }

}
