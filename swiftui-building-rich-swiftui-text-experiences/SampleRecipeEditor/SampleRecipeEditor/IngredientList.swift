/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The list of ingredients the inspector displays.
*/

import SwiftUI
import SwiftData

/// A list of ingredients.
///
/// The list visualizes the given name suggestion as a highlighted element with
/// a plus button at the bottom. When someone presses the button the view adds
/// the suggested ingredient to the given list of ingredients.
struct IngredientsList: View {
    let ingredientNameSuggestion: IngredientSuggestion?
    @Binding var selection: Set<Ingredient.ID>
    @Binding var ingredients: [Ingredient]

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Text("Ingredients")
                    .font(.headline)
                Spacer()
            }

            List {
                Group {
                    ForEach(ingredients) { ingredient in
                        Toggle(isOn: Binding(get: {
                            selection.contains(ingredient.id)
                        }, set: { newValue in
                            if newValue {
                                selection.insert(ingredient.id)
                            } else {
                                selection.remove(ingredient.id)
                            }
                        })) {
                            Text(ingredient.name)
                        }
                    }
                    .onDelete { offsets in
                        ingredients.remove(atOffsets: offsets)
                    }

                    NewIngredientRow(suggestedName: ingredientNameSuggestion?.suggestedName, onAdd: onAdd)
                        .zIndex(-1)
                }
                .listRowBackground(EmptyView())
            }
            .animation(.smooth, value: ingredients)
            .listStyle(.plain)
            .lineLimit(2)
        }
        .toggleStyle(IngredientToggleStyle())
    }

    private var onAdd: (() -> Void)? {
        if let ingredientNameSuggestion {
            {
                let ingredient = Ingredient(name: ingredientNameSuggestion.suggestedName)
                ingredients.append(ingredient)
                ingredientNameSuggestion.onApply(ingredient.id)
            }
        } else {
            nil
        }
    }
}

struct NewIngredientRow: View {
    let suggestedName: AttributedString?
    let onAdd: (() -> Void)?

    @State private var submitted = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Button("Add Ingredient", systemImage: "plus.circle.fill") {
                submitted = true
                onAdd?()
            }
            .keyboardShortcut("i", modifiers: .control)
            .labelStyle(.iconOnly)
            .disabled(isDisabled)
            .animation(displayName == "" ? nil : .smooth, value: displayName)

            Text(displayName)
                .animation(displayName == "" ? nil : .smooth, value: displayName)
            Spacer()
        }
        .onChange(of: AttributedString(suggestedName ?? "", including: AttributeScopes.IngredientNameAttributes.self)) {
            submitted = false
        }
        .opacity(isDisabled ? 0 : 1)
        .foregroundStyle(.white)
        .listRowSeparator(.hidden)
        .listRowBackground(
            Capsule()
                .foregroundStyle(isDisabled ? Color.clear : Color.green)
                .padding(.horizontal, 5))
    }

    private var displayName: AttributedString {
        if !submitted, let suggestedName {
            AttributedString(suggestedName, including: AttributeScopes.IngredientNameAttributes.self)
        } else {
            ""
        }
    }

    private var isDisabled: Bool {
        displayName.characters.isEmpty || onAdd == nil
    }
}

struct IngredientToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Button("Select Ingredient", systemImage: "checkmark.circle") {
                configuration.isOn.toggle()
            }
            .labelStyle(.iconOnly)
            .symbolVariant(configuration.isOn ? .fill : .none)
            .foregroundStyle(.green)

            configuration.label

            Spacer()
        }
    }
}
