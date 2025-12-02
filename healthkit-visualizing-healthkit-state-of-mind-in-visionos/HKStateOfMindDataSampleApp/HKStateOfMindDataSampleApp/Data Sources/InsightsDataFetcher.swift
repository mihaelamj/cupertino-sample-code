/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data fetcher for app insights.
*/

import Foundation
import HealthKit

struct InsightsDataFetcher {

    var calendarFetcher: CalendarFetcher { CalendarFetcher.shared }
    var healthStore: HKHealthStore { HealthStore.shared.healthStore }

    func event(
        matching label: HKStateOfMind.Label,
        calendarModels: [CalendarModel],
        dateInterval: DateInterval
    ) async throws -> EventModel? {
        // Fetch State of Mind samples.
        var stateOfMindSamples = try await fetchStateOfMindSamples(matching: label,
                                                                   calendarModels: calendarModels,
                                                                   dateInterval: dateInterval)

        // Sort samples by valence based on their label.
        stateOfMindSamples = sort(samples: stateOfMindSamples, with: label)

        // Fetch events.
        let events = try await calendarFetcher.findEvents(within: dateInterval, in: calendarModels)

        // Find any matching events for the sample collection and sort by the strongest feeling.
        for stateOfMindSample in stateOfMindSamples {
            if let event = findClosestEvent(to: stateOfMindSample, events: events) {
                return event
            }
        }
        return nil
    }

    func fetchStateOfMindSamples(matching label: HKStateOfMind.Label,
                                 calendarModels: [CalendarModel],
                                 dateInterval: DateInterval) async throws -> [HKStateOfMind] {
        var samples: [HKStateOfMind] = []
        for calendar in calendarModels {
            samples += try await fetchStateOfMindSamples(
                label: label,
                association: calendar.stateOfMindAssociation,
                dateInterval: dateInterval
            )
        }
        return samples
    }

    func fetchStateOfMindSamples(label: HKStateOfMind.Label,
                                 association: HKStateOfMind.Association,
                                 dateInterval: DateInterval) async throws -> [HKStateOfMind] {
        // Configure the query.
        let datePredicate = HKQuery.predicateForSamples(withStart: dateInterval.start, end: dateInterval.end)
        let associationPredicate = HKQuery.predicateForStatesOfMind(with: association)
        let labelPredicate = HKQuery.predicateForStatesOfMind(with: label)
        let compoundPredicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [datePredicate, associationPredicate, labelPredicate]
        )

        let stateOfMindPredicate = HKSamplePredicate.stateOfMind(compoundPredicate)
        let descriptor = HKSampleQueryDescriptor(predicates: [stateOfMindPredicate], sortDescriptors: [])

        return try await descriptor.result(for: healthStore)
    }

    func findClosestEvent(to stateOfMindSample: HKStateOfMind, events: [EventModel]) -> EventModel? {
        let numberOfMinutesAfterEventEnd: Double = 30
        let validEvents = events.filter { event in
            // Make sure the sample starts after the event.
            let isOnOrAfterStartDate = event.startDate <= stateOfMindSample.startDate
            // Allow for samples a person logs an arbitrary amount of time after the event.
            let flexibleEndDate = event.endDate.addingTimeInterval(60 * numberOfMinutesAfterEventEnd)
            // Make sure the sample starts before the flexible end of the event.
            let isBeforeOrOnFlexibleEndDate = flexibleEndDate >= stateOfMindSample.startDate
            return isOnOrAfterStartDate && isBeforeOrOnFlexibleEndDate
        }
        // Tie breaker: Pick the event with the end date closest to the sample start date.
        return validEvents.max {
            return $0.endDate.timeIntervalSince(stateOfMindSample.startDate) <
                $1.endDate.timeIntervalSince(stateOfMindSample.startDate)
        }
    }

    func sort(samples: [HKStateOfMind], with label: HKStateOfMind.Label) -> [HKStateOfMind] {
        var sortingMethod: (HKStateOfMind, HKStateOfMind) -> Bool
        switch label {
        case .angry, .sad:
            // Sort the most unpleasant samples first.
            sortingMethod = { $0.valence < $1.valence }
        case .happy, .satisfied:
            // Sort the most pleasant samples first.
            sortingMethod = { $0.valence > $1.valence }
        default:
            // Sort the strongest valence first.
            sortingMethod = { abs($0.valence) > abs($1.valence) }
        }
        return samples.sorted(by: sortingMethod)
    }

}
