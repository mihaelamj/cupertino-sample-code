/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Bird class, which contains the birds that live within backyards.
*/

import Foundation

final class Bird {
    let id: UUID
    var name: String? {
        didSet {
            displayName = name ?? speciesID
        }
    }
    var displayName: String

    var speciesID: String
    var favoriteFood: BirdFood
    var dislikedFoods: [BirdFood]

    var hueRotation: Double

    init(name: String? = nil,
         species: BirdSpecies,
         favoriteFood: BirdFood,
         dislikedFoods: [BirdFood] = [],
         hueRotation: Double = .random(in: 0..<1)) {
        self.id = UUID()
        self.name = name
        self.displayName = name ?? species.name
        self.speciesID = species.id
        self.favoriteFood = favoriteFood
        self.dislikedFoods = dislikedFoods
        self.hueRotation = hueRotation
    }
}

// MARK: - Temporary bird instances

extension Bird {
    static let preview = Bird(
        name: "Fluffington",
        species: .preview,
        favoriteFood: .preview
    )

    static func all(random: inout SeededRandomGenerator) -> [Bird] {
        let allBirdFoods = BirdFood.all()
        let allBirdSpecies = BirdSpecies.all()

        var all = [Bird]()
        for species in allBirdSpecies {
            let total = Int.random(in: 8..<23, using: &random)
            for _ in 0 ..< total {
                let favoriteFood = allBirdFoods.randomElement(using: &random)!
                var dislikedFoods: [BirdFood] = []
                let totalUnfavored = Int.random(in: 0..<3, using: &random)
                var remainingFood = allBirdFoods
                remainingFood.removeAll(where: { $0.id == favoriteFood.id })
                for _ in 0 ..< totalUnfavored {
                    let food = remainingFood.randomElement(using: &random)!
                    dislikedFoods.append(food)
                    remainingFood.removeAll(where: { $0.id == food.id })
                }
                all.append(Bird(
                    species: species,
                    favoriteFood: favoriteFood,
                    dislikedFoods: dislikedFoods,
                    hueRotation: .random(in: 0..<1, using: &random)
                ))
            }
        }
        return all
    }
}
