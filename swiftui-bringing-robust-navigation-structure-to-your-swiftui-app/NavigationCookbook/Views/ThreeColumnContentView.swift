/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content view for the three-column navigation split view experience.
*/

import SwiftUI

struct ThreeColumnContentView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(DataModel.self) private var dataModel
    private let categories = Category.allCases

    var body: some View {
        @Bindable var navigationModel = navigationModel
        NavigationSplitView(
            columnVisibility: $navigationModel.columnVisibility
        ) {
            List(
                categories,
                selection: $navigationModel.selectedCategory
            ) { category in
                NavigationLink(category.localizedName, value: category)
            }
            .navigationTitle("Categories")
        } content: {
            if let category = navigationModel.selectedCategory {
                List(selection: $navigationModel.selectedRecipe) {
                    ForEach(dataModel.recipes(in: category)) { recipe in
                        NavigationLink(recipe.name, value: recipe)
                    }
                }
                .navigationTitle(category.localizedName)
                .onDisappear {
                    if navigationModel.selectedRecipe == nil {
                        navigationModel.selectedCategory = nil
                    }
                }
                .experienceToolbar()
            } else {
                Text("Choose a category")
                    .navigationTitle("")
            }
        } detail: {
            RecipeDetail(recipe: navigationModel.selectedRecipe) { relatedRecipe in
                Button {
                    navigationModel.selectedCategory = relatedRecipe.category
                    navigationModel.selectedRecipe = relatedRecipe
                } label: {
                    RecipeTile(recipe: relatedRecipe)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview() {
    ThreeColumnContentView()
        .environment(NavigationModel(columnVisibility: .all))
        .environment(DataModel.shared)
}
