/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model that represents the primary components of a flight leg.
*/

import Foundation

struct FlightLegInfo: Hashable, Sendable {
    var origin: FlightInfo
    var destination: FlightInfo
}
