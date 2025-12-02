/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration of navigation experiences used to define the app architecture.
*/

import SwiftUI

/// An enumeration of navigation experiences used to define the app architecture.
enum Experience: Int, Identifiable, CaseIterable, Codable {
    case stack
    case twoColumn
    case threeColumn

    var id: Int { rawValue }

    /// The image name of the navigation experience.
    var imageName: String {
        switch self {
        case .stack: return "list.bullet.rectangle.portrait"
        case .twoColumn: return "sidebar.left"
        case .threeColumn: return "rectangle.split.3x1"
        }
    }
    
    /// The localized name of the navigation experience.
    var localizedName: LocalizedStringKey {
        switch self {
        case .stack: return "Stack"
        case .twoColumn: return "Two columns"
        case .threeColumn: return "Three columns"
        }
    }
    
    /// The localized descriptioon of the navigation experience.
    var localizedDescription: LocalizedStringKey {
        switch self {
        case .stack:
            return "Presents a stack of views over a root view."
        case .twoColumn:
            return "Presents views in two columns: sidebar and detail."
        case .threeColumn:
            return "Presents views in three columns: sidebar, content, and detail."
        }
    }
}
