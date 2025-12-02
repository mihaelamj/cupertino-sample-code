/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration of recipe groupings used to display sidebar items.
*/

import SwiftUI

enum Category: Int, Hashable, CaseIterable, Identifiable, Codable {
    case dessert
    case pancake
    case salad
    case sandwich

    var id: Int { rawValue }

    var localizedName: LocalizedStringKey {
        switch self {
        case .dessert:
            return "Dessert"
        case .pancake:
            return "Pancake"
        case .salad:
            return "Salad"
        case .sandwich:
            return "Sandwich"
        }
    }
}
