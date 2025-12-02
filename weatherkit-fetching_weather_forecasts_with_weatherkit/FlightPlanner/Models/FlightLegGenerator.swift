/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A model generator that creates flight legs based on the given flight leg
 components and calendar.
*/

import Foundation

enum FlightLegGenerator {
    
    /// Generates a flight leg for the given flight leg information and calendar.
    static func makeLeg(
        for legInfo: FlightLegInfo,
        in calendar: Calendar) -> FlightLeg? {
        let nextDeparture = makeDeparture(
            fromOrigin: legInfo.origin,
            in: calendar)
        
        guard let departure = nextDeparture else { return nil }
        
        let origin = legInfo.origin.airport
        let destination = legInfo.destination.airport
        
        let updatedDestination = FlightInfo(
            date: departure,
            airport: destination)
        
        let nextArrival = makeArrival(
            forDestination: updatedDestination,
            in: calendar)
        
        guard let arrival = nextArrival else { return nil }
        
        let leg = FlightLeg(
            origin: origin,
            destination: destination,
            departure: departure,
            arrival: arrival)
        return leg
    }
    
    private static func makeDeparture(
        fromOrigin origin: FlightInfo,
        in calendar: Calendar) -> Date? {
        // Add a random hour and minute.
        let dateComponents = DateComponents(
            calendar: calendar,
            hour: .random(in: 1...6),
            minute: .random(in: 11...59)
        )
        
        let departure = calendar.date(
            byAdding: dateComponents,
            to: origin.date)
        return departure
    }
    
    private static func makeArrival(
        forDestination destination: FlightInfo,
        in calendar: Calendar) -> Date? {
        // Add a random hour and minute.
        let dateComponents = DateComponents(
            calendar: calendar,
            hour: .random(in: 4...8),
            minute: .random(in: 1...59)
        )
        
        let arrival = calendar.date(
            byAdding: dateComponents,
            to: destination.date)
        return arrival
    }
}
