/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structures that demonstrate how to display a tip based on user state using a custom model type.
*/

import SwiftUI
import TipKit

struct FoodEventTip: Tip {
    struct Item: Codable, Sendable {
        var name: String
        var isFavorite: Bool
    }

    // Event triggered when a user views a specific food item.
    static let viewedSpecificFood: Tips.Event<Item> = Tips.Event(id: "viewed-specific-food")

    static let viewedDetailView = Tips.Event(id: "FoodDetailViewDidOpen")

    var title: Text {
        Text("Save as a Favorite")
    }

    var message: Text? {
        Text("Tap on the button to favorite an item.")
    }

    var image: Image? {
        Image(systemName: "fork.knife")
    }

    var rules: [Rule] {
        #Rule(FoodEventTip.viewedDetailView) {
            // This rule checks if the user donated to the `FoodDetailViewDidOpen` event at least once.
            $0.donations.count >= 1
        }
        #Rule(FoodEventTip.viewedSpecificFood) {
            // The events donated must contain at least three distinct items with different names.
            // This ensures the user explored a variety of options before showing the tip.
            $0.donations.smallestSubset(groupedBy: \.name).count > 1
        }
        #Rule(FoodEventTip.viewedSpecificFood) {
            // This rule checks if the user has donated to the `viewedSpecificFood` event more than four times
            // within the last hour for favorited items.
            $0.donations.donatedWithin(.hour)
                .filter({ $0.isFavorite == true }).count > 4
        }
    }

    var options: [Option] {
        // Show this tip once.
        MaxDisplayCount(1)
    }
}

struct FoodDetailView: View {
    // Create an instance of your tip content.
    let tip = FoodEventTip()

    // An array of food items with their names and favorite state.
    @State var foodItems: [FoodEventTip.Item] = [
        FoodEventTip.Item(name: "Pizza", isFavorite: false),
        FoodEventTip.Item(name: "Salad", isFavorite: false),
        FoodEventTip.Item(name: "Pasta", isFavorite: false),
        FoodEventTip.Item(name: "Burger", isFavorite: false),
        FoodEventTip.Item(name: "Sushi", isFavorite: false)
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Use events to track user interactions in your app. Then define rules based on those interactions to control when your tips appear.")
            HStack {
                ForEach($foodItems, id: \.self) { food in
                    FoodItem(food: food)
                        .popoverTip(tip)
                }
            }
            Text("Tap the button to favorite an item.")
        }
        .onAppear {
            FoodEventTip.viewedDetailView.sendDonation()
        }
        .padding()
        .navigationTitle("Food Options")
    }
}

struct FoodItem: View {
    @Binding
    var food: FoodEventTip.Item

    var body: some View {
        Button {
            food.isFavorite.toggle()

            // Donate to the event when the user action occurs.
            FoodEventTip.viewedSpecificFood.sendDonation(food)
        } label: {
            VStack {
                Text(food.name)
                Image(systemName: food.isFavorite ? "heart.fill" : "heart")
                    .foregroundColor(food.isFavorite ? .red : .primary)
            }
        }
    }
}

extension FoodEventTip.Item: Hashable { }

#Preview {
    FoodDetailView()
}
