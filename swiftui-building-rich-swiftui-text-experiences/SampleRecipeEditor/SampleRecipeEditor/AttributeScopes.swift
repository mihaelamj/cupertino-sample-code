/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The attribute scopes for recipe content editing, persistence, and ingredients
  in this app.
*/

import Foundation
import SwiftUI

extension AttributeScopes {
    /// Attributes that are allowed in the name of an ingredient.
    ///
    /// - Note: Use this attribute scope for serializing ingredients.
    struct IngredientNameAttributes: AttributeScope {
        let adaptiveImageGlyph: AttributeScopes.SwiftUIAttributes.AdaptiveImageGlyphAttribute
    }
}

extension AttributeScopes {
    /// Attributes that capture all encoded information in recipe text.
    ///
    /// - Note: Use this attribute scope for serializing recipe text content.
    struct RecipeModelAttributes: AttributeScope {
        /// The custom attributes are the basis of the recipe text model.
        let custom: CustomAttributes

        /// The font can hold information about whether a run is bold or not.
        let font: AttributeScopes.SwiftUIAttributes.FontAttribute

        /// Recipe text can include all the attributes that ingredient names
        /// use.
        let ingredientName: IngredientNameAttributes
    }
}

extension AttributeScopes {
    /// Attributes that capture all information and formatting available in the recipe editor.
    ///
    /// - Note: The recipe editor's `RecipeFormattingDefinition` uses this attribute scope.
    struct RecipeEditorAttributes: AttributeScope {
        /// All the semantic information of a recipe should be available in the
        /// `AttributedTextFormattingDefinition`.
        let model: RecipeModelAttributes

        /// The foreground color of a range of text.
        ///
        /// - Note: This attribute is not serialized, but inferred based on the `model` attributes
        /// by the `RecipeFormattingDefinition`.
        let foregroundColor: AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute
    }
}

extension AttributeScopes {
    struct CustomAttributes: AttributeScope {
        /// The attribute for specifying the semantic format for a recipe text paragraph.
        let paragraphFormat: ParagraphFormattingAttribute
        /// An attribute for marking text as a reference to a recipe's ingredient.
        let ingredient: IngredientAttribute
    }
}

/// The semantic format of a text paragraph.
enum ParagraphFormat: Codable {
    /// Regular text.
    case body
    /// A section header.
    case section
}

/// An attribute for specifying the semantic format for a recipe text paragraph.
struct ParagraphFormattingAttribute: CodableAttributedStringKey {
    typealias Value = ParagraphFormat

    static let name = "SampleRecipeEditor.ParagraphFormattingAttribute"

    static let runBoundaries: AttributedString.AttributeRunBoundaries? = .paragraph
    static let inheritedByAddedText: Bool = false
}

/// An attribute for marking text as a reference to a recipe's ingredient.
struct IngredientAttribute: CodableAttributedStringKey {
    typealias Value = Ingredient.ID

    static let name = "SampleRecipeEditor.IngredientAttribute"

    static let inheritedByAddedText: Bool = false
    static let invalidationConditions: Set<AttributedString.AttributeInvalidationCondition>? = [.textChanged]
}

extension AttributeDynamicLookup {
    /// The subscript for pulling custom attributes into the dynamic attribute lookup.
    ///
    /// This makes them available throughout the code, using the name they have in the
    /// `AttributeScopes.CustomAttributes` scope.
    subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.CustomAttributes, T>
    ) -> T {
        self[T.self]
    }
}
