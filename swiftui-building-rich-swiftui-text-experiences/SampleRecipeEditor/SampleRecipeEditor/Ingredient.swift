/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftData model for a recipe's ingredients.
*/

import SwiftData
import Foundation

@Model
final class Ingredient: Identifiable {
    /// A static identifier for an ingredient.
    ///
    /// - Note: SwiftData's synthesized identifier may change dynamically as the
    /// object saves. To ensure the `IngredientAttribute` can reliably
    /// identify ingredients, a static identifier is required.
    var id: UUID
    var name: AttributedString {
        get {
            nameModel.value
        }
        set {
            nameModel.value = newValue
        }
    }

    @Relationship(deleteRule: .cascade)
    private var nameModel: AttributedStringModel

    init(name: AttributedString) {
        self.id = UUID()
        self.nameModel = AttributedStringModel(value: name, scope: .ingredient)
    }
}
