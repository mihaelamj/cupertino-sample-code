/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The root navigation split view of this app.
*/

import SwiftUI
import SwiftData

struct RootView: View {
    @State private var selectedRecipe: Recipe?
    @State private var suggestion: IngredientSuggestion?

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationSplitView(sidebar: {
            RecipeList(selectedRecipe: $selectedRecipe)
        }, detail: {
            if let selectedRecipe {
                RecipeView(recipe: selectedRecipe)
            } else {
                Button("Create a recipe", systemImage: "square.and.pencil") {
                    let new = Recipe()
                    modelContext.insert(new)
                    selectedRecipe = new
                }
            }
        })
    }
}
