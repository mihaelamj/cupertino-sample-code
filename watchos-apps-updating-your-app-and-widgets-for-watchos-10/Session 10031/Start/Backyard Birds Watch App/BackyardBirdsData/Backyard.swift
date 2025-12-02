/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Backyard class, which holds the content of each backyard.
*/

import Foundation
import SwiftUI

final class Backyard: Identifiable, ObservableObject {
    
    struct BackyardBird: Identifiable {
        let name: String
        var imageName: String
        
        var id: String {
            name
        }
    }
    
    let id: UUID
    let imageName: String
    var name: String? {
        didSet {
            displayName = name ?? "Backyard"
        }
    }
    var displayName: String
    var stockDate: Date
    var creationDate: Date
    var presentingVisitor: Bool
    var visitorScore: Int
    
    let birds: [BackyardBird] = [
        BackyardBird(name: "Costa's Hummingbird", imageName: "Hummingbird"),
        BackyardBird(name: "Cedar Waxwing", imageName: "Petrel"),
        BackyardBird(name: "Spotted Dove", imageName: "Dove"),
        BackyardBird(name: "Brown-Chinned Sparrow", imageName: "Chickadee"),
        BackyardBird(name: "Allen's Hummingbird", imageName: "Hummingbird"),
        BackyardBird(name: "California Scrub-Jay", imageName: "Swallow")
    ]
       
       let statusColor: Color = .red

    var birdFood: BirdFood

    var visitorEvents = [BackyardVisitorEvent]()

    var leadingPlants = [Plant]()

    var trailingPlants = [Plant]()

    var currentVisitorEvent: BackyardVisitorEvent? {
        guard let event = visitorEvents.first(where: { $0.dateRange.contains(.now) }) else {
            return nil
        }
        return event
    }

    var hasVisitor: Bool {
        currentVisitorEvent != nil
    }

    var needsToPresentVisitor: Bool {
        hasVisitor && !presentingVisitor
    }

    init(name: String?, birdFood: BirdFood, imageName: String) {
        self.id = UUID()
        self.name = name
        self.displayName = name ?? "Backyard"
        self.birdFood = birdFood
        self.creationDate = .now
        self.stockDate = .now
        self.presentingVisitor = false
        self.imageName = imageName
        self.visitorScore = Int.random(in: 16..<30)
    }
}

extension Backyard {
    static let preview: Backyard = {
        let backyard = Backyard(name: "Nina's Nest", birdFood: .preview, imageName: "Backyard 1")
        backyard.leadingPlants = [
            Plant(name: "Ol' Sunshine", species: .preview),
            Plant(name: "Jazz", species: .preview),
            Plant(species: .preview)
        ]
        backyard.trailingPlants = [
            Plant(name: "Leafy", species: .preview),
            Plant(species: .preview),
            Plant(name: "Iceberg", species: .preview)
        ]
        return backyard
    }()

    static func all(random: inout SeededRandomGenerator) -> [Backyard] {
        let allPlantSpecies = PlantSpecies.all()
        let allBirdFood = BirdFood.all()

        var all = [Backyard]()
        let backyard1 = Backyard(name: "Nina's Nest", birdFood: allBirdFood.randomElement(using: &random)!, imageName: "Backyard 1")
        backyard1.leadingPlants = [
            Plant(name: "Ol' Sunshine", species: allPlantSpecies[0]),
            Plant(name: "Jazz", species: allPlantSpecies[3]),
            Plant(species: allPlantSpecies[1])
        ]
        backyard1.trailingPlants = [
            Plant(name: "Leafy", species: allPlantSpecies[4]),
            Plant(species: allPlantSpecies[0]),
            Plant(name: "Iceberg", species: allPlantSpecies[1])
        ]
        all.append(backyard1)

        var count = 1
        func generateRandomBackyard(name: String) -> Backyard {
            count += 1
            let backyard = Backyard(name: name, birdFood: allBirdFood.randomElement(using: &random)!, imageName: "Backyard \(count)")
            let leadingPlantCount = Int.random(in: 0...3, using: &random)
            let trailingPlantCount = Int.random(in: 0...3, using: &random)
            backyard.leadingPlants = (0..<leadingPlantCount).map { _ in
                Plant(species: allPlantSpecies.randomElement(using: &random)!)
            }

            backyard.trailingPlants = (0..<trailingPlantCount).map { _ in
                Plant(species: allPlantSpecies.randomElement(using: &random)!)
            }
            return backyard
        }

        all.append(generateRandomBackyard(name: "Matthew's Manor"))
        all.append(generateRandomBackyard(name: "John's Jungle"))
        all.append(generateRandomBackyard(name: "Anne's Abode"))
        all.append(generateRandomBackyard(name: "August's Acres"))

        return all
    }
}

extension Backyard: Hashable {
    static func == (lhs: Backyard, rhs: Backyard) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
