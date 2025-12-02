/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A component for the timing of the hike.
*/

import Foundation
import RealityKit

struct HikeTimingComponent: Component, Equatable {
    private var _departureDate: Date = MockData.departureTime
    var departureDate: Date {
        get {
            _departureDate
        }
        set {
            _departureDate = newValue
            // When someone changes the departure date via the UI, update the arrival time to match.
            updateArrivalTime()
        }
    }

    private var _arrivalDate: Date = .distantFuture
    var arrivalDate: Date {
        get {
            _arrivalDate
        }
        set {
            _arrivalDate = newValue
            // When someone changes the arrival date via the UI, update the departure time to match.
            _departureDate = _arrivalDate
                .addingTimeInterval(-hikeTime)
                .roundTo15Mins()
        }
    }

    // A dictionary that contains the rest stop durations.
    var restStopRestDurations: [RestStopLocation: Int] = [:] {
        didSet {
            if restStopRestDurations.values.reduce(0, +) != oldValue.values.reduce(0, +) {
                updateArrivalTime()
            }
        }
    }

    // Length of the trail in miles.
    var hikeLength: Double = 0

    var hikeTime: TimeInterval {
        // Given a 1 mph hiking speed, miles and hours are equivalent metrics.
        hikeLength * .oneHourInSeconds + TimeInterval(totalMinutesOfRest * 60)
    }

    // Total minutes of rest for all locations of the rest stop.
    var totalMinutesOfRest: Int {
        restStopRestDurations
            .map { $0.value }
            .reduce(0, +)
    }

    mutating
    private func updateArrivalTime() {
        _arrivalDate = _departureDate
            .addingTimeInterval(hikeTime)
            .roundTo15Mins()
    }
}
