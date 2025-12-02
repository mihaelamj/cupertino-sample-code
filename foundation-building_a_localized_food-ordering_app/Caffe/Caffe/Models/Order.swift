/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An item in an order, including the food item, size, quantity, and price.
*/

import Foundation

struct OrderItem: Identifiable {
    var id = UUID()
    let foodItem: FoodItem
    let foodSize: FoodSize
    let quantity: Int
    var price: Decimal {
        foodItem.price[foodSize]! * Decimal(quantity)
    }
}

struct Order {
    var items: [OrderItem] = []
    
    var count: Int {
        items.reduce(0) { (result: Int, item: OrderItem) -> Int in
            result + item.quantity
        }
    }
    
    var totalPrice: Decimal {
        items.reduce(0) { (result: Decimal, item: OrderItem) -> Decimal in
            result + item.price
        }
    }
}

extension Order {
    var isEmpty: Bool {
        return count == 0

    }
}
