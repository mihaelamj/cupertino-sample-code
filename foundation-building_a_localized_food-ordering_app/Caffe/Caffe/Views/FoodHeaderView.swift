/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A header view that shows localized, styled text for a food item.
*/

import SwiftUI

struct FoodHeaderView: View {
    
    private let food: FoodItem
    
    private var ingredientText: String {
        food.ingredients.map(\.localizedDescription).formatted(.list(type: .and))
    }
    
    var body: some View {
        Spacer()
        food.icon.image
            .resizable()
            .frame(width: 80, height: 80, alignment: .center)
            .padding([.leading, .trailing, .top], 20)
        Text(food.localizedName.capitalized)
            .font(.system(size: 60))
            .padding([.leading, .trailing], 20)
            .padding([.bottom], 20)
        Text("Our \(food.localizedName) is made from: \(ingredientText).")
            .padding([.leading, .trailing], 20)
    }

    init(food: FoodItem) {
        self.food = food
    }
}

struct FoodHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        FoodHeaderView(food: .salad)
    }
}
