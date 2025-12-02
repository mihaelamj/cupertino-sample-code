/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data source for calendar events and State of Mind samples.
*/

import Foundation
import HealthKit
import EventKit

/// Groups State of Mind data together for a given calendar and the given date range.
@Observable @MainActor final class CalendarStateOfMindData {
    let healthStore: HKHealthStore
    let calendar: CalendarModel

    /// The current samples from HealthKit, which views can reference and observe.
    fileprivate(set) var stateOfMindSamples: [HKStateOfMind]? = nil

    /// The date range for querying data.
    /// The range isn't inclusive of the end of the last day, fetching samples up to the end of that day (midnight the day after).
    fileprivate(set) var dateInterval: DateInterval

    /// The label to use to query State of Mind data.
    fileprivate(set) var stateOfMindLabel: HKStateOfMind.Label?

    init(healthStore: HKHealthStore,
         calendar: CalendarModel,
         dateInterval: DateInterval,
         stateOfMindLabel: HKStateOfMind.Label? = nil) {
        self.healthStore = healthStore
        self.calendar = calendar
        self.dateInterval = dateInterval
        self.stateOfMindLabel = stateOfMindLabel
    }
}

/// Fetches and maintains a dataset of `CalendarStateOfMindData` and coordinates changes in the date interval to keep the set coherent.
@Observable @MainActor class CalendarStateOfMindDataProvider {
    let healthStore: HKHealthStore

    var selectedCalendars: Set<CalendarModel> = [] {
        didSet {
            updateCalendarData(for: selectedCalendars)
        }
    }

    /// References to the open queries for each calendar, which the system keys by the calendar identifier.
    private var queryTasks: [String: Task<Void, any Error>] = [:]

    /// The date range for querying data.
    /// The range is *closed* over the last day, fetching samples up to the end of that day (midnight the day after).
    var dateInterval: DateInterval {
        didSet {
            // Fetch fresh data.
            calendarStateOfMindData = []
            updateCalendarData(for: selectedCalendars)
        }
    }

    /// The label to use to query State of Mind data.
    var stateOfMindLabel: HKStateOfMind.Label?

    /// The fetched data associated with each selected calendar, for the given date range.
    private(set) var calendarStateOfMindData: [CalendarStateOfMindData] = []

    init(healthStore: HKHealthStore,
         selectedCalendars: Set<CalendarModel>,
         dateInterval: DateInterval,
         stateOfMindLabel: HKStateOfMind.Label? = nil) {
        self.healthStore = healthStore
        self.selectedCalendars = selectedCalendars
        self.dateInterval = dateInterval
        self.stateOfMindLabel = stateOfMindLabel
        updateCalendarData(for: selectedCalendars)
    }

    func fetchAndObserveDataSources() {
        for calendarData in calendarStateOfMindData {
            fetchAndObserveData(for: calendarData)
        }
    }

    func stopObservingDataSources() {
        for calendarData in calendarStateOfMindData {
            stopObservation(for: calendarData)
        }
    }

    func fetchAndObserveData(for calendarData: CalendarStateOfMindData) {
        let descriptor = configureStateOfMindAnchoredObjectQuery(label: stateOfMindLabel,
                                                                 association: calendarData.calendar.stateOfMindAssociation)
        let sequence = descriptor.results(for: healthStore)

        queryTasks[calendarData.calendar.identifier] = Task(priority: .userInitiated) {
            // Use an AsyncSequence to receive updates.
            for try await sampleUpdate in sequence {
                print("Received update to samples from HealthKit: \(sampleUpdate)")
                // Begin with our existing model, or make an empty array.
                var updatedSampleCollection = calendarData.stateOfMindSamples ?? [HKStateOfMind]()
                // Update our model with the changes.
                updatedSampleCollection.removeAll(where: { existingSample in
                    sampleUpdate.deletedObjects.contains(where: { deletedSample in
                        deletedSample.uuid == existingSample.uuid
                    })
                })

                updatedSampleCollection.append(contentsOf: sampleUpdate.addedSamples)
                // Update our model with the new collection.
                calendarData.stateOfMindSamples = updatedSampleCollection
            }
        }
    }

    func configureStateOfMindAnchoredObjectQuery(label: HKStateOfMind.Label?,
                                                 association: HKStateOfMind.Association) -> HKAnchoredObjectQueryDescriptor<HKStateOfMind> {
        // Configure the query.
        var predicates = [NSPredicate]()

        predicates.append(HKQuery.predicateForSamples(withStart: dateInterval.start, end: dateInterval.end))
        predicates.append(HKQuery.predicateForStatesOfMind(with: association))
        if let label {
            predicates.append(HKQuery.predicateForStatesOfMind(with: label))
        }

        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        let stateOfMindPredicate = HKSamplePredicate.stateOfMind(compoundPredicate)
        let descriptor = HKAnchoredObjectQueryDescriptor(predicates: [stateOfMindPredicate], anchor: nil) // Do not resume from an anchor.

        // Fetch the results.
        return descriptor
    }

    func stopObservation(for calendarData: CalendarStateOfMindData) {
        queryTasks[calendarData.calendar.identifier]?.cancel()
        queryTasks[calendarData.calendar.identifier] = nil
    }

    private func updateDateInterval(_ dateInterval: DateInterval, for calendarDataToUpdate: CalendarStateOfMindData) {
        calendarDataToUpdate.dateInterval = dateInterval
        // Start an updated query.
        fetchAndObserveData(for: calendarDataToUpdate)
    }

    private func updateCalendarData(for calendars: Set<CalendarModel>) {
        var updatedData = [CalendarStateOfMindData]()
        for calendar in calendars {
            if let existingData = calendarStateOfMindData.first(where: { $0.calendar == calendar }) {
                updatedData.append(existingData)
            } else {
                let newData = CalendarStateOfMindData(healthStore: healthStore,
                                                      calendar: calendar,
                                                      dateInterval: dateInterval,
                                                      stateOfMindLabel: stateOfMindLabel)
                fetchAndObserveData(for: newData)
                updatedData.append(newData)
            }
        }
        // Set with a consistent sort order.
        self.calendarStateOfMindData = updatedData.sorted(by: { $0.calendar.title < $1.calendar.title })
    }
}
