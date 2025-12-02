/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An enumeration that represents the journey type for a flight segment,
 either a one-way or a round-trip flight.
*/

import Foundation

enum FlightJourney: Int, CaseIterable, Identifiable, Sendable {
    case oneWay
    case roundTrip
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .oneWay:
            return "One way"
        case .roundTrip:
            return "Round trip"
        }
    }
    
    var systemImage: String {
        switch self {
        case .oneWay:
            return "arrow.right"
        case .roundTrip:
            return "arrow.right.arrow.left"
        }
    }
}
