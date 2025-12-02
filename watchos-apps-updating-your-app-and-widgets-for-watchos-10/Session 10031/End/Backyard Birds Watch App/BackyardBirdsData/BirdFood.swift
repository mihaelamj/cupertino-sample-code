/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Bird Food class.
*/

import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "Backyard Birds Data", category: "BirdFood")

final class BirdFood {
    let id: String
    var name: String
    var summary: String
    var isPremium: Bool
    var priority: Int

    init(id: String, name: String, summary: String, isPremium: Bool = false) {
        self.id = id
        self.name = name
        self.summary = summary
        self.isPremium = isPremium
        self.priority = isPremium ? 1 : 0
    }
}

// MARK: - All bird food

extension BirdFood {
    var image: Image {
        Image("Bird Food/\(id)")
            .resizable()
    }
}

extension BirdFood {
    static let preview = BirdFood(
        id: "Sunflower Seeds",
        name: "Sunflower Seeds",
        summary: "A placeholder description of sunflower seeds."
    )
}

extension BirdFood {
    static func all() -> [BirdFood] {
        return [
            BirdFood(
                id: "Golden Seed",
                name: "Golden Seed",
                summary: "Birds crave this golden treat",
                isPremium: true
            ),

            BirdFood(
                id: "Sunflower Seeds",
                name: "Sunflower Seeds",
                summary: "A placeholder description of sunflower seeds."
            ),

            BirdFood(
                id: "Corn",
                name: "Corn",
                summary: "A placeholder description of corn."
            ),

            BirdFood(
                id: "Millet Seeds",
                name: "Millet Seeds",
                summary: "A placeholder description of millet seeds."
            ),

            BirdFood(
                id: "Peanuts",
                name: "Peanuts",
                summary: "A placeholder description of peanuts."
            ),

            BirdFood(
                id: "Safflower Seeds",
                name: "Safflower Seeds",
                summary: "A placeholder description of safflower seeds."
            ),

            BirdFood(
                id: "Sorghum Seeds",
                name: "Sorghum Seeds",
                summary: "A placeholder description of sorghum seeds."
            )
        ]
    }
}
