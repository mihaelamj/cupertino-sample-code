/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The enumeration the app uses to describe tab elements in the UI.
*/

import Foundation
import SwiftUI

/// Values that represent the app's tabs, properties you can use to identify a tab and display tab names as localizable strings.
enum Tabs: Equatable, Hashable, Identifiable {
    /// A tab that displays all of the IAP types in a consolidated view.
    case allInOne
    /// A tab that demonstrates an IAP for a single consumable item.
    case consumable
    /// A tab that demonstrates an IAP for a single non-consumable item.
    case nonconsumable
    /// A tab that demonstrates an IAP for a collection of the subscription options.
    case allSubscriptions

    /// The tab's identifier.
    var id: Int {
        switch self {
        case .allInOne:
            return 0
        case .consumable:
            return 1
        case .nonconsumable:
            return 2
        case .allSubscriptions:
            return 3
        }
    }
    /// A localizable string to use in a tab control's title to display the tab's name or in a view to describe the tab's contents.
    var name: String {
        switch self {
        case .allInOne: String(localized: "All", comment: "Tab title")
        case .consumable: String(localized: "Consumables", comment: "Tab title")
        case .nonconsumable: String(localized: "Non-Consumables", comment: "Tab title")
        case .allSubscriptions: String(localized: "Subscriptions", comment: "Tab title")
        }
    }
}
