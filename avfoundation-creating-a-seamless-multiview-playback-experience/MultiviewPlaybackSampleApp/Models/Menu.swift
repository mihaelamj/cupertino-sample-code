/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data structures to represent values from the JSON menu.
*/

import Foundation
import AVFoundation

typealias DataModel = (Codable & Equatable & Sendable)

struct Menu: DataModel {
    let item: MenuItem
}

// Information for creating a menu item from the JSON menu.
struct MenuItem: DataModel, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let assets: [MenuAsset]
}

// Information for creating an item asset from the JSON menu.
struct MenuAsset: DataModel, Identifiable, Hashable {
    let id: UUID
    let name: String
    let url: String
    let networkPriority: NetworkPriority?
}

// MARK: - Type Extenstions

enum NetworkPriority: Int, DataModel {
    case defaultPriority
    case lowPriority
    case highPriority
}

extension NetworkPriority {
    // Convert the menu network priority type from an integer to an `AVPlayer.NetworkResourcePriority` type.
    func asAVFNetworkPriority() -> AVPlayer.NetworkResourcePriority {
        switch self {
        case .defaultPriority:
            return .default
        case .lowPriority:
            return .low
        case .highPriority:
            return .high
        }
    }
}

