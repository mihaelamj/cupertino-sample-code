/*
See LICENSE folder for this sample’s licensing information.

Abstract:
View that shows the available items and an order button.
*/

import SwiftUI

struct ContentView: View {
    @State private var order: Order = Order()
    @State private var foodItemSelection: FoodItem = .pizza
    @State private var presentDetailsView: Bool = false
    @State private var presentReceiptView: Bool = false

    private let gridColumns = [
        GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 20),
        GridItem(.adaptive(minimum: 250, maximum: 500), spacing: 20)
    ]

    var body: some View {
        VStack(alignment: .leading) {
            RainbowText("^[Fast](rainbow: 'fun') & ^[Delicious](rainbow: 'extreme') Food")
                .font(.slogan)
                .frame(maxWidth: 260, alignment: .leading)

            LazyVGrid(columns: gridColumns, spacing: 20) {
                ForEach(FoodItem.allFoodItems) { (item: FoodItem) in
                    FoodCard(food: item)
                        .onTapGesture {
                            foodItemSelection = item
                            presentDetailsView = true
                        }
                }
            }

            Spacer()

            Button(action: onOrderComplete) {
                Text("Order ^[\(order.count) item](inflect: true) for \(order.totalPrice.formatted(.currency(code: "USD")))")
            }
            .buttonStyle(OrderButtonStyle())
            .disabled(order.isEmpty)
        }
        .padding([.horizontal, .top], 20.0)
        .sheet(isPresented: $presentDetailsView) {
            FoodDetailsView(food: $foodItemSelection, onSelectionComplete: onSelectionComplete)
        }
        .sheet(isPresented: $presentReceiptView) {
            ReceiptView(withOrder: order)
        }
    }
    
    private func onSelectionComplete(_ orderItem: OrderItem) {
        order.items.append(orderItem)
        presentDetailsView = false
    }
    
    private func onOrderComplete() {
        presentReceiptView = true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
