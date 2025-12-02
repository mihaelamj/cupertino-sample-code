/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftData persistence model for recipes.
*/

import SwiftData
import Foundation

@Model
final class Recipe: Identifiable {
    var lastModified: Date
    var name: String
    @Relationship(deleteRule: .cascade)
    var ingredients: [Ingredient]

    var content: AttributedString {
        get {
            contentModel.value
        }
        set {
            contentModel.value = newValue
            lastModified = .now
        }
    }

    @Relationship(deleteRule: .cascade)
    private var contentModel: AttributedStringModel

    @Attribute(.externalStorage)
    var image: Data?

    init(name: String, content: AttributedString, ingredients: [Ingredient]) {
        self.name = name
        self.ingredients = ingredients
        self.lastModified = .now
        self.contentModel = AttributedStringModel(value: content, scope: .recipe)
    }

    convenience init() {
        self.init(name: "", content: "", ingredients: [])
    }
}

