/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A detail view the app uses to display the metadata for a given recipe,
  as well as its related recipes.
*/

import SwiftUI

struct RecipeDetail<Link: View>: View {
    var recipe: Recipe
    var relatedLink: (Recipe) -> Link

    var body: some View {
        Content(recipe: recipe, relatedLink: relatedLink)
            .focusedSceneValue(\.selectedRecipe, recipe)
    }
}

private struct Content<Link: View>: View {
    var recipe: Recipe
    var dataModel = DataModel.shared
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

    private var wideDetails: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack {
                    image
                    ratingPicker
                }
                VStack(alignment: .leading) {
                    title.padding(.bottom)
                    ingredients
                }
                .padding()
            }
            Divider()
            relatedRecipes
        }
    }

    private var narrowDetails: some View {
        let alignment: HorizontalAlignment
        #if os(macOS)
        alignment = .leading
        #else
        alignment = .center
        #endif
        return VStack(alignment: alignment, spacing: 22) {
            title
            VStack {
                image
                ratingPicker
            }
            ingredients
            Divider()
            relatedRecipes
        }
    }
    
    private var title: some View {
        #if os(macOS)
        Text(recipe.name)
            .font(.largeTitle.bold())
        #else
        EmptyView()
        #endif
    }

    private var image: some View {
        RecipePhoto(recipe: recipe)
            .frame(width: 300, height: 300)
            .clipShape(.rect(cornerRadius: 20))
    }

    @State private var rating: Rating?

    private var ratingPicker: some View {
        RatingPicker(rating: $rating) { Text("Rating") }
            .labelsHidden()
    }

    @ViewBuilder
    private var ingredients: some View {
        VStack(alignment: .leading) {
            Text("Ingredients")
                .font(.title2.bold())
                .padding(.bottom, 8)
            VStack(alignment: .leading) {
                ForEach(recipe.ingredients) { ingredient in
                    HStack(alignment: .firstTextBaseline) {
                        Text("•")
                        Text(ingredient.description)
                    }
                }
            }
        }
        .frame(minWidth: 300, alignment: .leading)
    }

    @ViewBuilder
    private var relatedRecipes: some View {
        if !recipe.related.isEmpty {
            VStack(alignment: .leading) {
                Text("Related Recipes")
                    .font(.headline)
                    .padding(.bottom, 8)
                LazyVGrid(columns: columns, alignment: .leading) {
                    let relatedRecipes = dataModel.recipes(relatedTo: recipe)
                    ForEach(relatedRecipes) { relatedRecipe in
                        relatedLink(relatedRecipe)
                    }
                }
            }
        }
    }

    private var columns: [GridItem] {
        [ GridItem(.adaptive(minimum: 120, maximum: 120), spacing: 20) ]
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview {
    RecipeDetail(recipe: .mock) { _ in
        EmptyView()
    }
}
