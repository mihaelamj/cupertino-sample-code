/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model for a grocery list.
*/

import SwiftUI

struct GroceryList: Codable {
    struct Item: Codable, Hashable, Identifiable {
        var id = UUID()
        var name: String
        var isObtained: Bool = false
    }

    var items: [Item] = []

    mutating func addItem() -> Item {
        let item = GroceryList.Item(name: "")
        items.append(item)
        return item
    }
}

extension GroceryList {
    static var sample = GroceryList(items: [
        GroceryList.Item(name: "Apples"),
        GroceryList.Item(name: "Lasagna"),
        GroceryList.Item(name: "")
    ])
}
