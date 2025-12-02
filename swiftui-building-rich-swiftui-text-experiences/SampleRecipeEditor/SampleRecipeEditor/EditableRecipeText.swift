/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model for a recipe with editable content.
*/

import SwiftUI

@MainActor
@Observable
final class EditableRecipeText: Identifiable {
    let model: Recipe

    var text: AttributedString {
        get {
            // SwiftData periodically saves the recipe while a person types, and
            // checks for changes to the model from other sources, like changes
            // from cloud storage. The editor needs to handle situations where
            // the text in the editor and the text in the SwiftData model
            // diverge. This code just chooses the newer version of the two. A
            // real app might compute the difference between the two variants,
            // attempt to merge them, and ask the user to resolve conflicts
            // where necessary.
            if lastModified >= model.lastModified {
                editedText
            } else {
                model.content
            }
        }
        set {
            model.content = newValue
            editedText = newValue
        }
    }

    private var editedText: AttributedString {
        didSet {
            lastModified = .now
        }
    }
    private var lastModified: Date

    var selection: AttributedTextSelection

    init(recipe: Recipe) {
        self.model = recipe
        self.selection = AttributedTextSelection()
        self.editedText = model.content
        self.lastModified = model.lastModified
    }
}
