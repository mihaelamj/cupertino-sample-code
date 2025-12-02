/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A list of recipes, based on a given recipe category.
*/

import SwiftUI

struct RecipeList: View {
    var body: some View {
        List(
            categories,
            selection: $navigationModel.selectedCategory
        ) { category in
            NavigationLink(category.localizedName, value: category)
        }
        .navigationTitle("Categories")
        .toolbar {
            ExperienceButton(isActive: $showExperiencePicker)
        }
    }
}

struct RecipeList_Previews: PreviewProvider {
    static var previews: some View {
        RecipeList()
    }
}
