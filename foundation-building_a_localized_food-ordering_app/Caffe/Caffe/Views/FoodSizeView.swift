/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows a selection UI for a specific size for a given food.
*/

import SwiftUI

struct FoodSizeLabel: View {
    var food: FoodItem
    var size: FoodSize

    var body: some View {
        HStack {
            Text(size.localizedName.capitalized)
            Spacer()
            Text(food.localizedPrice(size))
        }
    }
}

struct FoodSizeToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn = true
        } label: {
            HStack {
                if configuration.isOn {
                    Image(systemName: "checkmark.circle.fill")
                } else {
                    Image(systemName: "circle.dashed")
                }
                configuration.label
            }
            .foregroundColor(.primary)
        }
    }
}

struct FoodSizeView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            Toggle(isOn: .constant(true)) {
                FoodSizeLabel(food: .sandwich, size: .small)
            }
            .toggleStyle(FoodSizeToggleStyle())
        }
    }
}
