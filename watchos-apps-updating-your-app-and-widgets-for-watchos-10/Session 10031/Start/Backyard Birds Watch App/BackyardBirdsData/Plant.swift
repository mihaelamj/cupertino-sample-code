/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Plant class, which contains the plants in the backyards.
*/

import Foundation
import OSLog

private let logger = Logger(subsystem: "Backyard Birds Data", category: "Plant")

final class Plant {
    let id: UUID
    var name: String? {
        didSet {
            displayName = name ?? speciesID
        }
    }
    var displayName: String
    var speciesID: String
    var backyard: Backyard?

    init(id: UUID = UUID(), name: String? = nil, species: PlantSpecies) {
        logger.info("Creating plant model: \(name ?? species.name)")
        self.id = id
        self.name = name
        self.displayName = name ?? species.name
        self.speciesID = species.id
    }
}

// MARK: - Preview

extension Plant {
    static let preview = Plant(name: "Spikey", species: .preview)

    static func generateIndividualPlants(random: inout SeededRandomGenerator) {
        logger.info("Generating individual plants...")
        let allPlantSpecies = PlantSpecies.all()
        logger.info("Found all plant species, now generating plants...")
        for species in allPlantSpecies {
            let count = Int.random(in: 1...3, using: &random)
            for _ in 0 ..< count {
                _ = Plant(species: species)
            }
        }
        logger.info("completed generating individual plants")
    }
}
