/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Mobile Agent Movement Type defines how a Mobile Agent is moving throughout its itinerary.
*/

import Foundation

extension MobileAgent {
    enum MovementType: Int {
        case unset = 0
        case normal = 1
        case revisit = 2
        case park = 3
    }
}
