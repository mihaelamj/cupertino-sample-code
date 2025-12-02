/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how to display a tip based on app state using a custom data type.
*/

import SwiftUI
import TipKit

struct AddPlantTip: Tip {
    var title: Text {
        Text("Add a plant to favorites")
    }

    var message: Text? {
        Text("Add plants to your favorites list")
    }

    var image: Image? {
        Image(systemName: "camera.macro")
    }

    var options: [TipOption] {
        MaxDisplayCount(1)
    }
}

struct FavoritePlantTip: Tip {
    // Define a custom value type to store a list of plant names.
    struct FavoritePlants: Codable, Sendable {
        var plants: Set<String> = []

        var arrayValue: [String] {
            Array(plants)
        }

        mutating func setPlants(_ newValue: [String]) {
            plants = Set(newValue)
        }
    }

    // Reset to default value the first time it is referenced.
    @Parameter(.transient)
    static var favoritePlants: FavoritePlants = FavoritePlants(plants: ["Sunflower", "Cactus"])

    var title: Text {
        Text("Explore Favorite Plants")
    }

    var message: Text? {
        Text("Discover your favorite plants and flowers.")
    }

    var image: Image? {
        Image(systemName: "leaf.fill")
    }

    // Tip will only display when there are 3 or more favorite plants and Rose has been favorited.
    var rules: [Rule] {
        // Display if more than two favorite plants are added.
        #Rule(FavoritePlantTip.$favoritePlants) {
            $0.plants.count >= 3
        }

        // Display if "Rose" is added as a favorite.
        #Rule(FavoritePlantTip.$favoritePlants) {
            $0.plants.contains("Rose")
        }
    }
}

struct FavoritePlantsView: View {
    // Collection of all available plants.
    static let allPlants: Set<String> = ["Rose", "Oak", "Maple", "Lily", "Orchid"]

    // Create an instance of your tip content.
    let favoritePlantTip = FavoritePlantTip()
    let addPlantTip = AddPlantTip()

    // Favorited plants.
    @State
    var favorites: [String] = ["Sunflower", "Cactus"]

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Use the parameter property wrapper and rules to track app state and control where and when your tip appears.")

                Text("Tip will only appear when there are at least 3 favorite plants and Rose has been favorited.")
            }
            .padding()
            List {
                ForEach(Array(favorites.enumerated()), id: \.offset) { (idx, plant) in
                    if idx == 0 {
                        Text(plant)
                            .popoverTip(favoritePlantTip)
                    } else {
                        Text(plant)
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button("Add plant") {
                        guard let nextPlant = Self.allPlants.first(where: { !favorites.contains($0) }) else {
                            return
                        }
                        withAnimation {
                            // Trigger a change in app state to make the tip appear or disappear.
                            favorites.append(nextPlant)
                            FavoritePlantTip.favoritePlants.setPlants(favorites)
                        }
                    }
                    .popoverTip(addPlantTip)
                }
            }
            .navigationTitle("Favorite plants")
        }
    }
}

#Preview {
    FavoritePlantsView()
}
