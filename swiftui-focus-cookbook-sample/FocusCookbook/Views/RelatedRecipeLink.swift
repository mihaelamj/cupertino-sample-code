/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A recipe tile, displaying the recipe's photo and name, that displays
 related recipes in the recipe detail view.
*/

import SwiftUI

struct RelatedRecipeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .contentShape(.rect(cornerRadius: 20))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct RelatedRecipeLink: View {
    var recipe: Recipe

    private var imageShape: RoundedRectangle {
        .rect(cornerRadius: 20)
    }

    var body: some View {
        NavigationLink(value: recipe.id) {
            VStack {
                RecipePhoto(recipe: recipe)
                    .frame(width: 120)
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(imageShape)
                    .overlay(
                        imageShape
                            .stroke(.gray.opacity(0.3), lineWidth: 0.5)
                    )
                Text(recipe.name)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.caption)
            }
        }
        .buttonStyle(RelatedRecipeButtonStyle())
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview {
    RelatedRecipeLink(recipe: .mock)
}
