/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The attributed text formatting definition for rich text in this app.
*/

import SwiftUI

/// The formatting definition the recipe editor uses.
struct RecipeFormattingDefinition: AttributedTextFormattingDefinition {
    typealias Scope = AttributeScopes.RecipeEditorAttributes

    let ingredients: Set<Ingredient.ID>

    var body: some AttributedTextFormattingDefinition<Scope> {
        NormalizeFonts()
        // Below constraints reading the font attribute can rely on its value being
        // either `.title`, `.default.bold()`, or `nil`.
        IngredientsAreGreen(ingredients: ingredients)
        BoldUsesAccentColor()
    }
}

/// A constraint normalizing fonts to either `.title`, `.default.bold()`, or `nil`.
struct NormalizeFonts: AttributedTextValueConstraint {
    typealias Scope = RecipeFormattingDefinition.Scope
    typealias AttributeKey = AttributeScopes.SwiftUIAttributes.FontAttribute

    func constrain(_ container: inout Attributes) {
        guard container.paragraphFormat != .section else {
            container.font = .title
            return
        }

        guard let font = container.font, font != .default.bold() else {
            return
        }

        // Resolve the font in the default environment, because how the original font
        // looks in the editor is less important than how it looks in a generic context.
        let resolved = font.resolve(in: EnvironmentValues().fontResolutionContext)

        if resolved.isBold || resolved.isItalic {
            container.font = .default.bold()
        } else {
            container.font = nil
        }
    }
}

/// A constraint that ensures all valid ingredients appear in green.
///
/// Removing an ingredient from the list in the inspector removes it
/// from `ingredients` as well, so any ingredients in the text currently marked
/// with that ingredient's ID lose the green color.
struct IngredientsAreGreen: AttributedTextValueConstraint {
    typealias Scope = RecipeFormattingDefinition.Scope
    typealias AttributeKey = AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute

    /// The set of all valid ingredients.
    let ingredients: Set<Ingredient.ID>

    func constrain(_ container: inout Attributes) {
        if let ingredient = container.ingredient, ingredients.contains(ingredient) {
            container.foregroundColor = .green
        } else {
            container.foregroundColor = nil
        }
    }
}

/// All bold text that is not an ingredient should appear in the accent color.
struct BoldUsesAccentColor: AttributedTextValueConstraint {
    typealias Scope = RecipeFormattingDefinition.Scope
    typealias AttributeKey = AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute

    func constrain(_ container: inout Attributes) {
        guard container.ingredient == nil || container.foregroundColor == nil else {
            return
        }

        if container.font == .default.bold() {
            container.foregroundColor = .accentColor
        } else {
            container.foregroundColor = nil
        }
    }
}
