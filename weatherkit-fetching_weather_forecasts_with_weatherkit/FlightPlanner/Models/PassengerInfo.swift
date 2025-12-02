/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model that represents the number of passengers for a flight segment.
*/

import Foundation

struct PassengerInfo: Sendable {
    var adultsCount = 0
    var childrenCount = 0
    var infantsCount = 0
}
