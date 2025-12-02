/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The recipe list that appears in the navigation bar, along with logic for
  loading, creating, deleting, and saving recipes.
*/

import SwiftData
import SwiftUI

struct RecipeList: View {
    @Binding var selectedRecipe: Recipe?

    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor(\Recipe.lastModified)])
    private var recipes: [Recipe]

    private var selection: Binding<Recipe.ID?> {
        Binding(get: {
            selectedRecipe?.id
        }, set: { newValue in
            if let newValue {
                selectedRecipe = recipes.first(where: { $0.id == newValue })
            } else {
                selectedRecipe = nil
            }
        })
    }

    var body: some View {
        List(selection: selection) {
            ForEach(recipes) { recipe in
                @Bindable var recipe = recipe
                if recipe.id == selectedRecipe?.id {
                    NameField(name: $recipe.name)
                } else {
                    Text(recipe.name)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    let recipe = recipes[index]
                    modelContext.delete(recipe)
                    if selectedRecipe?.id == recipe.id {
                        selectedRecipe = nil
                    }
                }
            }
        }
        .toolbar {
            Button("Add Recipe", systemImage: "square.and.pencil") {
                let new = Recipe()
                modelContext.insert(new)
                selectedRecipe = new
            }
        }
        .onAppear {
            if selectedRecipe == nil {
                selectedRecipe = recipes.first
            }
        }
        .onChange(of: selectedRecipe) {
            // Real-world apps may need better logging infrastructure.
            print("Saving...")
            // Real-world apps may need better error handling.
            try? modelContext.save()
        }
    }
}

struct NameField: View {
    @Binding var name: String

    var body: some View {
        TextField("Title", text: $name, prompt: Text("Recipe name"))
            .onSubmit {
                if name.isEmpty {
                    name = "New Recipe"
                }
            }
            .onDisappear {
                if name.isEmpty {
                    name = "New Recipe"
                }
            }
    }
}
