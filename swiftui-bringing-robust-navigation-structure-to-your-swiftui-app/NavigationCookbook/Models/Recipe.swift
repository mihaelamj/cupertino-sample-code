/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model for a recipe and its metadata, including its related recipes.
*/

import SwiftUI

/// A data model for a recipe and its metadata, including its related recipes.
struct Recipe: Decodable, Hashable, Identifiable {
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case ingredients
        case related
        case imageName
    }
    
    let id: UUID
    
    /// The name of the recipe.
    var name: String
    
    /// The category of the recipe.
    var category: Category
    
    /// The ingredients used in the recipe.
    var ingredients: [Ingredient]
    
    /// The recipes related to this recipe instance.
    var related: [Recipe.ID] = []
    
    /// The image name of the recipe.
    var imageName: String? = nil
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let idString = try container.decode(String.self, forKey: .id)
        id = UUID(uuidString: idString)!
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(Category.self, forKey: .category)
        ingredients = try container.decode([Ingredient].self, forKey: .ingredients)
        let relatedIdStrings = try container.decode([String].self, forKey: .related)
        related = relatedIdStrings.compactMap(UUID.init(uuidString:))
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName)
    }
}

extension Recipe {
    
    /// The mock data representing a recipe. Used for previews.
    static var mock: Recipe {
        DataModel.shared.recipes[0]
    }
}
