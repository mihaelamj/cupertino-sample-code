/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The App Entity for `OrderDetailsAppEntity`.
*/

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct OrderDetailsAppEntity: TransientAppEntity {
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Order Details")

    @Property(title: "Estimated Time")
    var estimatedTime: DateComponents?

    @Property(title: "Total")
    var total: IntentCurrencyAmount?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Unimplemented")
    }

    init() {}
}

