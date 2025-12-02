/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content view for the navigation stack view experience.
*/

import SwiftUI

struct StackContentView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(DataModel.self) private var dataModel
    private let categories = Category.allCases

    var body: some View {
        @Bindable var navigationModel = navigationModel
        NavigationStack(path: $navigationModel.recipePath) {
            List(categories) { category in
                Section {
                    ForEach(dataModel.recipes(in: category)) { recipe in
                        NavigationLink(recipe.name, value: recipe)
                    }
                } header: {
                    Text(category.localizedName)
                }
            }
            .navigationTitle("Categories")
            .experienceToolbar()
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
        }
    }
}

#Preview() {
    StackContentView()
        .environment(DataModel.shared)
        .environment(NavigationModel.shared)
}
