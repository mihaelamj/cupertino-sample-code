/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model generator that creates flight segments based on the given flight
 components and calendar.
*/

import Foundation

enum FlightSegmentGenerator {
    
    /// Generates a flight segment for the given flight information and calendar.
    static func segment(
        byAdding flightInfo: [FlightInfo],
        in calendar: Calendar
    ) -> FlightSegment? {
        let linkedPairs = zip(flightInfo, flightInfo.dropFirst())
        let legInfo: [FlightLegInfo] = linkedPairs.compactMap {
            guard $0.airport != $1.airport else { return nil }
            return FlightLegInfo(origin: $0, destination: $1)
        }
        
        var legs = [FlightLeg]()
        for info in legInfo {
            if let leg = FlightLegGenerator.makeLeg(for: info, in: calendar) {
                legs.append(leg)
            }
        }
        return FlightSegment(legs: legs)
    }
}
