/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A food item available for purchase in the app.
*/

import SwiftUI

struct FoodItem: Identifiable, Hashable {
    
    struct Icon: Identifiable, Hashable {
        let id: String
        let image: Image
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        init(name: String) {
            id = name
            image = Image(name)
        }
    }
    
    let id = UUID()
    let icon: Icon
    let backgroundColor: Color
    let localizedName: String
    let price: [FoodSize: Decimal]
    let ingredients: [Ingredient]
        
    static let pizza: FoodItem = FoodItem(
        icon: Icon(name: "pizza"),
        backgroundColor: .backgroundBlue,
        localizedName: String(localized: "pizza"),
        price: [.small: 12, .large: 18, .huge: 22],
        ingredients: [.prosciutto, .cheese, .flour, .tomatoes]
    )
    static let juice: FoodItem = FoodItem(
        icon: Icon(name: "juice"),
        backgroundColor: .backgroundOrange,
        localizedName: String(localized: "juice"),
        price: [.small: 5, .large: 8, .huge: 12],
        ingredients: [.orange]
    )
    static let sandwich: FoodItem = FoodItem(
        icon: Icon(name: "sandwich"),
        backgroundColor: .backgroundYellow,
        localizedName: String(localized: "sandwich"),
        price: [.small: 10, .large: 15, .huge: 16],
        ingredients: [.bread, .lettuce, .cheese, .ham]
    )
    static let salad: FoodItem = FoodItem(
        icon: Icon(name: "salad"),
        backgroundColor: .backgroundGreen,
        localizedName: String(localized: "salad"),
        price: [.small: 8, .large: 12, .huge: 18],
        ingredients: [.lettuce, .cheese, .tomatoes, .ham])
    
    static let allFoodItems: [FoodItem] = [
        .pizza,
        .juice,
        .sandwich,
        .salad
    ]

    func localizedPrice(_ size: FoodSize) -> String {
        price[size]!.formatted(.currency(code: "USD"))
    }
}

enum FoodSize: Int, Identifiable, CaseIterable {
    case small
    case large
    case huge

    var id: Int { rawValue }
    var localizedName: String {
        switch self {
        case .small:
            return String(localized: "small")
        case .large:
            return String(localized: "large")
        case .huge:
            return String(localized: "huge")
        }
    }
}

struct Ingredient: Hashable {
    let localizedDescription: String
    
    static let prosciutto = Ingredient(localizedDescription: String(localized: "prosciutto"))
    static let cheese = Ingredient(localizedDescription: String(localized: "cheese"))
    static let flour = Ingredient(localizedDescription: String(localized: "flour"))
    static let tomatoes = Ingredient(localizedDescription: String(localized: "tomatoes"))
    static let cream = Ingredient(localizedDescription: String(localized: "cream"))
    static let sugar = Ingredient(localizedDescription: String(localized: "sugar"))
    static let chocolate = Ingredient(localizedDescription: String(localized: "chocolate"))
    static let bread = Ingredient(localizedDescription: String(localized: "bread"))
    static let lettuce = Ingredient(localizedDescription: String(localized: "lettuce"))
    static let orange = Ingredient(localizedDescription: String(localized: "orange"))
    static let ham = Ingredient(localizedDescription: String(localized: "ham"))
}
