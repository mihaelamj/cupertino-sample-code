/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A recipe tile, displaying the recipe's photo and name.
*/

import SwiftUI

struct RecipeTile: View {
    var recipe: Recipe
    var isSelected: Bool

    private var strokeStyle: AnyShapeStyle {
        isSelected
            ? AnyShapeStyle(.selection)
            : AnyShapeStyle(.clear)
    }

    var body: some View {
        VStack {
            photoView
            captionView
        }
    }
}

extension RecipeTile {
    private var photoView: some View {
        RecipePhoto(recipe: recipe)
            .frame(minWidth: 120, maxWidth: Self.size)
            .aspectRatio(1, contentMode: .fill)
            .clipShape(.containerRelative)
            .padding(Self.selectionStrokeWidth)
            .overlay(
                ContainerRelativeShape()
                    .inset(by: -Self.selectionStrokeWidth / 1.5)
                    .strokeBorder(
                        strokeStyle,
                        lineWidth: Self.selectionStrokeWidth)
            )
            .shadow(color: .black.opacity(0.05), radius: 0.5, x: 0, y: -1)
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            .containerShape(.rect(cornerRadius: 20))
    }

    private var captionView: some View {
        Text(recipe.name)
            .lineLimit(1)
            .truncationMode(.tail)
            .font(.headline)
    }
}

extension RecipeTile {
    static let size: CGFloat = 240
    static let selectionStrokeWidth: CGFloat = 4
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview {
    RecipeTile(recipe: .mock, isSelected: true)
}
