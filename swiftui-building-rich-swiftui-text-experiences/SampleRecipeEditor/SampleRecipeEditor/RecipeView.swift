/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The recipe view to use as the detail of the base navigation view.
*/

import SwiftUI

/// The detail view for a single recipe.
///
/// This view sets up the inspector and toolbar items relevant for the recipe
/// as a whole. It also initializes the view model for the recipe editor and the
/// recipe editor itself.
struct RecipeView: View {
    @Bindable var model: Recipe

    @State private var content: EditableRecipeText
    @State private var showIngredientsInspector = true
    @State private var showSettingsSheet = false

    init(recipe: Recipe) {
        self.model = recipe
        self._content = State(initialValue: EditableRecipeText(recipe: recipe))
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            BackgroundView(imageData: model.image)

            RecipeEditor(content: content)
                .scrollContentBackground(.hidden)
                .contentMargins(.horizontal, 16, for: .scrollContent)
                .navigationTitle(model.name)
                .navigationBarTitleDisplayMode(.large)
        }
        .inspector(isPresented: $showIngredientsInspector) {
            InspectorView(
                recipe: model,
                ingredientNameSuggestion: content.ingredientNameSuggestion,
                ingredientSelectionSuggestion: content.ingredientSelectionSuggestion
            )
        }
        .sheet(isPresented: $showSettingsSheet) {
            RecipeSettings(recipe: model)
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Toggle("Show Ingredients", systemImage: "basket", isOn: $showIngredientsInspector)
                    .tint(.green)
            }

            ToolbarItemGroup(placement: .topBarLeading) {
                RecipeShareLink(recipe: model)

                Toggle("Show Recipe Settings", systemImage: "ellipsis.circle", isOn: $showSettingsSheet)
            }
        }
        .toolbarRole(.editor)
        .onChange(of: model) {
            content = EditableRecipeText(recipe: model)
        }
        .attributedTextFormattingDefinition(RecipeFormattingDefinition(
            ingredients: Set(model.ingredients.map(\.id))
        ))
    }
}

extension EditableRecipeText {
    fileprivate var ingredientSelectionSuggestion: Set<Ingredient.ID> {
        let selectedAttributes = selection.attributes(in: text)
        let ingredientIdentifiers = selectedAttributes[\.ingredient].compactMap(\.self)

        return Set(ingredientIdentifiers)
    }

    fileprivate var ingredientNameSuggestion: IngredientSuggestion {
        let name = text[selection]

        return IngredientSuggestion(
            suggestedName: AttributedString(name),
            onApply: { ingredientId in
                let ranges = RangeSet(self.text.characters.ranges(of: name.characters))

                self.text.transform(updating: &self.selection) { text in
                    text[ranges].ingredient = ingredientId
                }
            })
    }
}
