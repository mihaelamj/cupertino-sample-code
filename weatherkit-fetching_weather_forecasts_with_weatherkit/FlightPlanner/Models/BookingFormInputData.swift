/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The data model that stores the user's input when adding a new flight segment
 to the itinerary.
*/

import Foundation

@MainActor
struct BookingFormInputData: Sendable {
    var journey: FlightJourney
    var passengerInfo: PassengerInfo
    var destination: Airport?
    var arrivalDate: Date
    private var originInfo: FlightInfo
    
    init(
        journey: FlightJourney = .roundTrip,
        passengerInfo: PassengerInfo = PassengerInfo(adultsCount: 1),
        origin: Airport = .sfo,
        departureDate: Date = .now,
        destination: Airport? = nil,
        arrivalDate: Date = .now
    ) {
        self.journey = journey
        self.passengerInfo = passengerInfo
        self.destination = destination
        self.arrivalDate = arrivalDate
        originInfo = FlightInfo(date: departureDate, airport: origin)
    }
    
    private var destinationInfo: FlightInfo? {
        guard let airport = destination else { return nil }
        return FlightInfo(date: arrivalDate, airport: airport)
    }
    
    var origin: Airport {
        get { originInfo.airport }
        set { originInfo.airport = newValue }
    }
    
    var departureDate: Date {
        get { originInfo.date }
        set { originInfo.date = newValue }
    }
    
    var flightInfo: [FlightInfo]? {
        guard let destinationInfo = destinationInfo else { return nil }
        switch journey {
        case .oneWay:
            return [ originInfo, destinationInfo ]
        case .roundTrip:
            let arrivalDate = destinationInfo.date
            let destination = destinationInfo.airport
            let departingFlightInfo = [
                originInfo,
                FlightInfo(date: departureDate, airport: destination)
            ]
            let returnFlightInfo = [
                destinationInfo,
                FlightInfo(date: arrivalDate, airport: origin)
            ]
            return departingFlightInfo + returnFlightInfo
        }
    }
    
    func save(to flightData: FlightData, in calendar: Calendar) async {
        guard let flightInfo = flightInfo else { return }
        let newSegment = FlightSegmentGenerator.segment(
            byAdding: flightInfo,
            in: calendar)
        if let segment = newSegment {
            flightData.addSegment(segment)
        }
    }
}
