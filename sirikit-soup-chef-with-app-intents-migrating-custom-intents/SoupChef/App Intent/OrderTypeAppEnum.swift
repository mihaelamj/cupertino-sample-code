/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
App enumeration for `OrderTypeAppEnum`.
*/

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum OrderTypeAppEnum: String, AppEnum {
    
    case pickup
    case delivery

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Order Type")
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .pickup: "pickup",
        .delivery: "delivery"
    ]
}

