/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows the icon and localized name of a food item.
*/

import SwiftUI

struct FoodCard: View {
    private let food: FoodItem
    
    var body: some View {
        ZStack {
            food.backgroundColor
            VStack {
                Spacer()
                food.icon.image
                    .resizable()
                    .frame(width: 60, height: 60, alignment: .center)
                    .padding(EdgeInsets(top: 30, leading: 0, bottom: 30, trailing: 0))
                HStack {
                    Text(food.localizedName.capitalized)
                        .font(.cardTitle)
                        .kerning(2.0)
                        .textCase(.uppercase)
                    Spacer()
                    Image(systemName: "arrow.up.forward.app.fill")
                        .foregroundColor(.secondary)
                }.padding(15)
            }
        }
        .cornerRadius(10.0)
        .contentShape(Rectangle())
    }
    
    init(food: FoodItem) {
        self.food = food
    }
}

struct FoodCard_Previews: PreviewProvider {
    static var previews: some View {
        FoodCard(food: .salad)
    }
}
