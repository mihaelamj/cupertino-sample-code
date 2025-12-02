/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Commands that act upon a recipe.
*/

import SwiftUI

struct SelectedRecipeKey: FocusedValueKey {
    typealias Value = Recipe
}

extension FocusedValues {
    var selectedRecipe: SelectedRecipeKey.Value? {
        get { self[SelectedRecipeKey.self] }
        set { self[SelectedRecipeKey.self] = newValue }
    }
}

struct RecipeCommands: Commands {
    @FocusedValue(\.selectedRecipe)
    private var selectedRecipe: Recipe?

    var body: some Commands {
        CommandMenu("Recipe") {
            Group {
                Button {
                    addStep(for: selectedRecipe)
                } label: {
                    if let selectedRecipe {
                        Text("Add Step for \(selectedRecipe.name)…")
                    } else {
                        Text("Add Step…")
                    }
                }
                Divider()
                Button("Favorite") {
                    favorite(selectedRecipe)
                }
                Divider()
                Button("Add to Grocery List") {
                    addIngredientsToGroceryList(for: selectedRecipe)
                }
            }
            .disabled(selectedRecipe == nil)
        }
    }

    private func addStep(for recipe: Recipe?) {
        // ...
    }

    private func favorite(_ recipe: Recipe?) {
        // ...
    }

    private func addIngredientsToGroceryList(for recipe: Recipe?) {
        // ...
    }
}
