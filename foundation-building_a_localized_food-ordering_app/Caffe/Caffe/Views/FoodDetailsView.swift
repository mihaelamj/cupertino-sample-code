/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View that shows the available sizes and corresponding prices for a food item.
*/

import SwiftUI

struct FoodDetailsView: View {
    @Binding var food: FoodItem
    let onSelectionComplete: (OrderItem) -> Void

    @State private var quantity: Int = 0
    @State private var foodSizeSelection: FoodSize = .small

    var body: some View {
        VStack(alignment: .leading) {
            FoodHeaderView(food: food)

            Form {
                Section(header: Text("Size")) {
                    ForEach(FoodSize.allCases) { size in
                        Toggle(isOn: isSizeSelected(size)) {
                            FoodSizeLabel(food: food, size: size)
                        }
                        .toggleStyle(FoodSizeToggleStyle())
                    }
                }

                Section(header: Text("Quantity")) {
                    Stepper("\(quantity)", value: $quantity, in: 0...10)
                }
            }

            Button(
                "Add ^[\(quantity) \(foodSizeSelection.localizedName) \(food.localizedName)](inflect: true) to your order",
                action: orderButtonTapped
            )
            .buttonStyle(OrderButtonStyle())
            .padding(.horizontal, 20.0)
            .disabled(quantity == 0)
        }
    }

    private func orderButtonTapped() {
        let orderItem: OrderItem = OrderItem(foodItem: food, foodSize: foodSizeSelection, quantity: quantity)
        onSelectionComplete(orderItem)
    }

    private func isSizeSelected(_ size: FoodSize) -> Binding<Bool> {
        Binding<Bool> {
            foodSizeSelection == size
        } set: { isSelected in
            if isSelected {
                foodSizeSelection = size
            }
        }
    }
}

struct FoodDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        FoodDetailsView(food: .constant(.pizza), onSelectionComplete: { _ in })
    }
}
