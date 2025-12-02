/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The content view for the two-column navigation split view experience.
*/

import SwiftUI

struct TwoColumnContentView: View {
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
        } detail: {
            NavigationStack(path: $navigationModel.recipePath) {
                RecipeGrid()
            }
            .experienceToolbar()
        }
    }
}

#Preview() {
    TwoColumnContentView()
        .environment(DataModel.shared)
        .environment(NavigationModel.shared)
}
