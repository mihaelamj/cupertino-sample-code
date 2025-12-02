/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An inspector view featuring a list of ingredients and a button that simulates
  adding selected ingredients to a shopping list.
*/

import SwiftUI

struct IngredientSuggestion: Hashable {
    let suggestedName: AttributedString
    let onApply: @MainActor (Ingredient.ID) -> Void

    init(
        suggestedName: AttributedString,
        onApply: @MainActor @escaping (Ingredient.ID) -> Void = { _ in }
    ) {
        self.suggestedName = suggestedName
        self.onApply = onApply
    }

    static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.suggestedName == rhs.suggestedName
    }

    func hash(into hasher: inout Hasher) {
        suggestedName.hash(into: &hasher)
    }
}

struct InspectorView: View {
    @Bindable
    var recipe: Recipe
    let ingredientNameSuggestion: IngredientSuggestion?
    let ingredientSelectionSuggestion: Set<Ingredient.ID>

    @State private var selection: Set<Ingredient.ID> = []

    var body: some View {
        DispatchingChanges(to: ingredientNameSuggestion, id: recipe.id) { suggestion in
            IngredientsList(
                ingredientNameSuggestion: suggestion,
                selection: $selection,
                ingredients: $recipe.ingredients
            )
            .attributedTextFormattingDefinition(AttributeScopes.IngredientNameAttributes.self)
        }
        .onChange(of: ingredientSelectionSuggestion) {
            self.selection = ingredientSelectionSuggestion
        }

        Spacer()

        Button("Add to shopping list", systemImage: "cart.badge.plus") {
            // Symbolic implementation only.
            print("Added \(selection.count) items to the shopping list")
        }
        .tint(.green)
        .buttonStyle(.borderedProminent)
        .padding(.vertical)
    }

    private func addIngredient(_ suggestion: IngredientSuggestion) {
        let ingredient = Ingredient(name: suggestion.suggestedName)
        recipe.ingredients.append(ingredient)
    }
}
