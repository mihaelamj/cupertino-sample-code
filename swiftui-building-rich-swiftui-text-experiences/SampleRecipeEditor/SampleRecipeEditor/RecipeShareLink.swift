/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A share link for exporting a recipe's text content as rich text.
*/

import SwiftUI

struct RecipeShareLink: View {
    let recipe: Recipe
    @Environment(\.self) private var environment

    var body: some View {
        ShareLink(
            item: AttributedTextFormatting.Transferable(text: recipe.content, in: environment),
            subject: Text("Try my recipe for \(recipe.name)"),
            preview: SharePreview("\(recipe.name)"))
    }
}
