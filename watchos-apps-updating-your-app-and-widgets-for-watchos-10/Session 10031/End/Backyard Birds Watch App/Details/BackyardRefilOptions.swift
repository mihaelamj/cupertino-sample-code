/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The modal the app presents when the backyard needs to refill its water or food.
*/

import SwiftUI

struct BackyardRefillOptions: View {
    @EnvironmentObject private var backyard: Backyard
    @Environment(\.dismiss) private var dismiss: DismissAction
    @State private var selectedFood = "Corn"
    let foodOptions = ["Corn", "Bird seed", "Bugs", "Berries"]
    @Binding var waterValue: Int
    @State var value = 0
    @Binding var foodValue: Int
    let step = 1
    let range = 0...10
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Label("Water:", systemImage: "drop.fill")
                    .foregroundColor(.blue)
                Stepper(value: $value,
                               in: range,
                        step: step) {
                    Text("\(value)")
                }
            Label("Food: ", systemImage: "fork.knife")
                    .foregroundColor(.yellow)
                Picker(selection: $selectedFood) {
                    ForEach(foodOptions, id: \.self) { foodOption in
                        Text(foodOption)
                    }
                } label: {
                    Text("")
                }
                .labelsHidden()
                .frame(minHeight: 75)

                Spacer()
                Button("Save") {
                    foodValue += 5
                    waterValue += value
                    dismiss()
                }
            }
            .navigationTitle("Refill")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
    
    private var titleText: Text {
        Text(Image(systemName: "drop.fill")).foregroundColor(.blue) + Text("Water Remaining: ").foregroundColor(.blue) + Text("10 gallons")
    }
}
