/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A navigation model used to persist and restore the navigation state.
*/

import SwiftUI
import Combine

/// A navigation model used to persist and restore the navigation state.
@Observable
final class NavigationModel: Codable {
    
    /// The selected recipe category; otherwise returns `nil`.
    var selectedCategory: Category?
    
    /// The homogenous navigation state used by the app's navigation stacks.
    var recipePath: [Recipe]
    
    /// The leading columns' visibility state used by the app's navigation split views.
    var columnVisibility: NavigationSplitViewVisibility
    
    /// The leading columns' visibility state used by the app's navigation split views.
    var showExperiencePicker = false
    
    /// The shared JSON decoder object.
    private static let decoder = JSONDecoder()
    
    /// The shared JSON encoder object.
    private static let encoder = JSONEncoder()
    
    /// The URL for the JSON file that stores the recipe data.
    private static var dataURL: URL {
        .cachesDirectory.appending(path: "NavigationData.json")
    }
    
    /// The shared singleton navigation model object.
    static let shared: NavigationModel = {
        if let model = try? NavigationModel(contentsOf: dataURL) {
            return model
        } else {
            return NavigationModel()
        }
    }()

    /// Initialize a `NavigationModel` that enables programmatic control of leading columns’
    /// visibility, selected recipe category, and navigation state based on recipe data.
    init(columnVisibility: NavigationSplitViewVisibility = .automatic,
         selectedCategory: Category? = nil,
         recipePath: [Recipe] = []
    ) {
        self.columnVisibility = columnVisibility
        self.selectedCategory = selectedCategory
        self.recipePath = recipePath
    }
    
    /// Initialize a `DataModel` with the contents of a `URL`.
    private convenience init(
        contentsOf url: URL,
        options: Data.ReadingOptions = .mappedIfSafe
    ) throws {
        let data = try Data(contentsOf: url, options: options)
        let model = try Self.decoder.decode(Self.self, from: data)
        self.init(
            columnVisibility: model.columnVisibility,
            selectedCategory: model.selectedCategory,
            recipePath: model.recipePath)
    }

    /// Loads the navigation data for the navigation model from a previously saved state.
    func load() throws {
        let model = try NavigationModel(contentsOf: Self.dataURL)
        selectedCategory = model.selectedCategory
        recipePath = model.recipePath
        columnVisibility = model.columnVisibility
    }
    
    /// Saves the JSON data for the navigation model at its current state.
    func save() throws {
        try jsonData?.write(to: Self.dataURL)
    }
    
    /// The selected recipe; otherwise returns `nil`.
    var selectedRecipe: Recipe? {
        get { recipePath.first }
        set { recipePath = [newValue].compactMap { $0 } }
    }

    /// The JSON data used to encode and decode the navigation model at its current state.
    var jsonData: Data? {
        get { try? Self.encoder.encode(self) }
        set {
            guard let data = newValue,
                  let model = try? Self.decoder.decode(Self.self, from: data)
            else { return }
            selectedCategory = model.selectedCategory
            recipePath = model.recipePath
            columnVisibility = model.columnVisibility
        }
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.selectedCategory = try container.decodeIfPresent(
            Category.self, forKey: .selectedCategory)
        let recipePathIds = try container.decode(
            [Recipe.ID].self, forKey: .recipePathIds)
        self.recipePath = recipePathIds.compactMap { DataModel.shared[$0] }
        self.columnVisibility = try container.decode(
            NavigationSplitViewVisibility.self, forKey: .columnVisibility)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(selectedCategory, forKey: .selectedCategory)
        try container.encode(recipePath.map(\.id), forKey: .recipePathIds)
        try container.encode(columnVisibility, forKey: .columnVisibility)
    }

    enum CodingKeys: String, CodingKey {
        case selectedCategory
        case recipePathIds
        case columnVisibility
    }
}
