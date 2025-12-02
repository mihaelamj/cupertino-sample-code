/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The PlantSpecies class.
*/

import Foundation

final class PlantSpecies {

    let id: String
    var name: String
    var summary: String
    var waterConsumptionRate: Double

    init(id: String, name: String, summary: String, waterConsumptionRate: Double) {
        self.id = id
        self.name = name
        self.summary = summary
        self.waterConsumptionRate = waterConsumptionRate
    }
}

// MARK: - Individual species

extension PlantSpecies {
    static let preview = PlantSpecies(
        id: "Cactus",
        name: "Cactus",
        summary: "A low-maintence desert-dwelling plant. A wonderful addition to any backyard. Handle with care.",
        waterConsumptionRate: 0.5
    )

    static func all() -> [PlantSpecies] {
        [
            PlantSpecies(
                id: "Plant Species 1",
                name: "Plant Species 1",
                summary: "A summary of plant species 1",
                waterConsumptionRate: 1.2
            ),

            PlantSpecies(
                id: "Plant Species 2",
                name: "Plant Species 2",
                summary: "A summary of plant species 2",
                waterConsumptionRate: 0.9
            ),

            PlantSpecies(
                id: "Plant Species 3",
                name: "Plant Species 3",
                summary: "A summary of plant species 3",
                waterConsumptionRate: 0.95
            ),

            PlantSpecies(
                id: "Plant Species 4",
                name: "Plant Species 4",
                summary: "A summary of plant species 4",
                waterConsumptionRate: 1.1
            ),

            PlantSpecies(
                id: "Plant Species 5",
                name: "Plant Species 5",
                summary: "A summary of plant species 5",
                waterConsumptionRate: 1
            )
        ]
    }
}
