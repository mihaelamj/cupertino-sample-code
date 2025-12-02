/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A grid of recipe tiles, based on a given recipe category.
*/

import SwiftUI

struct RecipeGrid: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(DataModel.self) private var dataModel
    
    var body: some View {
        if let category = navigationModel.selectedCategory {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(dataModel.recipes(in: category)) { recipe in
                        NavigationLink(value: recipe) {
                            RecipeTile(recipe: recipe)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle(category.localizedName)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetail(recipe: recipe) { relatedRecipe in
                    Button {
                        navigationModel.recipePath.append(relatedRecipe)
                    } label: {
                        RecipeTile(recipe: relatedRecipe)
                    }
                    .buttonStyle(.plain)
                }
                .experienceToolbar()
            }
        } else {
            Text("Choose a category")
                .navigationTitle("")
        }
    }

    var columns: [GridItem] {
        [ GridItem(.adaptive(minimum: 240)) ]
    }
}

#Preview() {
    RecipeGrid()
        .environment(DataModel.shared)
        .environment(NavigationModel(selectedCategory: .dessert))
}

#Preview() {
    RecipeGrid()
        .environment(DataModel.shared)
        .environment(NavigationModel(selectedCategory: nil))
}
