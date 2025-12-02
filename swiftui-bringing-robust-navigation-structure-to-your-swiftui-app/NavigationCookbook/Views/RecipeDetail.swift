/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A detail view the app uses to display the metadata for a given recipe,
 as well as its related recipes.
*/

import SwiftUI

struct RecipeDetail<Link: View>: View {
    var recipe: Recipe?
    var relatedLink: (Recipe) -> Link

    var body: some View {
        if let recipe {
            Content(recipe: recipe, relatedLink: relatedLink)
                .id(recipe.id)
        } else {
            Text("Choose a recipe")
                .navigationTitle("")
        }
    }
}

private struct Content<Link: View>: View {
    @Environment(DataModel.self) private var dataModel
    var recipe: Recipe
    var relatedLink: (Recipe) -> Link

    var body: some View {
        ScrollView {
            ViewThatFits(in: .horizontal) {
                wideDetails
                narrowDetails
            }
            .scenePadding()
        }
        .navigationTitle(recipe.name)
    }

    var wideDetails: some View {
        VStack(alignment: .leading) {
            title
            HStack(alignment: .top, spacing: 20) {
                image
                ingredients
                Spacer()
            }
            relatedRecipes
        }
    }
    
    @ViewBuilder
    var narrowDetails: some View {
        #if os(macOS)
        HStack {
            narrowDetailsContent
            Spacer()
        }
        #else
        narrowDetailsContent
        #endif
    }

    var narrowDetailsContent: some View {
        VStack(alignment: narrowDetailsAlignment) {
            title
            image
            ingredients
            relatedRecipes
        }
    }
    
    var narrowDetailsAlignment: HorizontalAlignment {
        #if os(macOS)
        .leading
        #else
        .center
        #endif
    }
    
    @ViewBuilder
    var title: some View {
        #if os(macOS)
        Text(recipe.name)
            .font(.largeTitle)
            .bold()
        #endif
    }

    var image: some View {
        RecipePhoto(recipe: recipe)
            .frame(width: 300, height: 300)
    }

    @ViewBuilder
    var ingredients: some View {
        let padding = EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0)
        VStack(alignment: .leading) {
            Text("Ingredients")
                .font(.title2)
                .bold()
                .padding(padding)
            VStack(alignment: .leading) {
                ForEach(recipe.ingredients) { ingredient in
                    Text(ingredient.description)
                }
            }
        }
        .frame(minWidth: 300, alignment: .leading)
    }

    @ViewBuilder
    var relatedRecipes: some View {
        let padding = EdgeInsets(top: 16, leading: 0, bottom: 8, trailing: 0)
        if !recipe.related.isEmpty {
            VStack(alignment: .leading) {
                Text("Related Recipes")
                    .font(.title2)
                    .bold()
                    .padding(padding)
                LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
                    let relatedRecipes = dataModel.recipes(relatedTo: recipe)
                    ForEach(relatedRecipes) { relatedRecipe in
                        relatedLink(relatedRecipe)
                    }
                }
            }
        }
    }

    var columns: [GridItem] {
        [ GridItem(.adaptive(minimum: 120, maximum: 120)) ]
    }
}

#Preview() {
    RecipeDetail(recipe: .mock) { _ in
        EmptyView()
    }
    .environment(DataModel.shared)
}
