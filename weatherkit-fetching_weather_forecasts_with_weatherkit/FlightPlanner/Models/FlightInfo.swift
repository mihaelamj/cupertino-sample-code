/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model that represents the primary components of a single flight
 to or from an airport, and a date.
*/

import Foundation

struct FlightInfo: Hashable, Sendable {
    var date: Date = .now
    var airport: Airport
}

#if DEBUG
// Use this for preview data.
extension FlightInfo {
    static var sfo: FlightInfo {
        FlightInfo(date: .now, airport: .sfo)
    }
}
#endif
