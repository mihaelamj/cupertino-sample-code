/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A recipe tile, displaying the recipe's photo and name.
*/

import SwiftUI

struct RecipeTile: View {
    var recipe: Recipe
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading) {
            RecipePhoto(recipe: recipe)
                .aspectRatio(1, contentMode: .fill)
                .frame(maxWidth: 240, maxHeight: 240)
            Text(recipe.name)
                .lineLimit(2, reservesSpace: true)
        }
        .tint(.primary)
        .scaleEffect(CGSize(width: scale, height: scale))
        .onHover { isHovering = $0 }
    }
    
    var scale: CGFloat {
        isHovering ? 1.05 : 1
    }
}

#Preview() {
    RecipeTile(recipe: .mock)
}
