/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A navigation model used to persist and restore the navigation state.
*/

import SwiftUI
import Observation

@Observable final class NavigationModel: Codable {
    var selectedCategory: Category? = nil
    var recipePath: [Recipe.ID] = []
    var groceryList: GroceryList = GroceryList()

    private var decoder = JSONDecoder()
    private var encoder = JSONEncoder()

    init(selectedCategory: Category? = nil,
         recipePath: [Recipe.ID] = [],
         groceryList: GroceryList = GroceryList()
    ) {
        self.selectedCategory = selectedCategory
        self.recipePath = recipePath
        self.groceryList = groceryList
    }

    var selectedRecipeID: Recipe.ID? {
        get { recipePath.first }
        set { recipePath = [newValue].compactMap { $0 } }
    }

    var jsonData: Data? {
        get { try? encoder.encode(self) }
        set {
            guard let data = newValue,
                  let model = try? decoder.decode(Self.self, from: data)
            else { return }
            selectedCategory = model.selectedCategory
            recipePath = model.recipePath
            groceryList = model.groceryList
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.selectedCategory = try container.decodeIfPresent(
            Category.self, forKey: .selectedCategory)
        let recipePathIDs = try container.decode(
            [Recipe.ID].self, forKey: .recipePathIDs)
        self.recipePath = recipePathIDs
        self.groceryList = try container.decode(
            GroceryList.self, forKey: .groceryList)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(selectedCategory, forKey: .selectedCategory)
        try container.encode(recipePath, forKey: .recipePathIDs)
        try container.encode(groceryList, forKey: .groceryList)
    }

    enum CodingKeys: String, CodingKey {
        case selectedCategory
        case recipePathIDs
        case groceryList
    }
}
