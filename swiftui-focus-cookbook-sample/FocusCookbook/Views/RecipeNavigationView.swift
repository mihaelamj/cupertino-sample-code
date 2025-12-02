/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content view for the two-column navigation split view experience.
*/

import SwiftUI

struct RecipeNavigationView: View {
    @Bindable var navigationModel: NavigationModel
    @Binding var showGroceryList: Bool
    var categories = Category.allCases
    var dataModel = DataModel.shared

    @State private var selectedRecipe: Recipe.ID?

    var body: some View {
        NavigationSplitView {
            List(categories, selection: $navigationModel.selectedCategory) { category in
                NavigationLink(category.localizedName, value: category)
            }
            .navigationTitle("Categories")
            #if os(iOS)
            .toolbar {
                GroceryListButton(isActive: $showGroceryList)
            }
            #endif
        } detail: {
            NavigationStack(path: $navigationModel.recipePath) {
                RecipeGrid(category: navigationModel.selectedCategory, selection: $selectedRecipe)
            }
        }
    }
}
