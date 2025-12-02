/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The rich text editor for the text content of the recipe.
*/

import SwiftUI

struct RecipeEditor: View {
    @Bindable var content: EditableRecipeText

    var body: some View {
        TextEditor(text: $content.text, selection: $content.selection)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Picker("Paragraph Format", selection: $content.paragraphFormat) {
                        Text("Section")
                            .tag(ParagraphFormat.section)
                        Text("Body")
                            .tag(ParagraphFormat.body)
                    }
                    .pickerStyle(.inline)
                    .fixedSize()
                }
            }
    }
}

extension EditableRecipeText {
    /// The paragraph format the current selection exhibits.
    fileprivate var paragraphFormat: ParagraphFormat {
        get {
            let containers = selection.attributes(in: text)
            let formats = containers[\.paragraphFormat]

            return formats.contains(.section) ? .section : .body
        }
        set {
            text.transformAttributes(in: &selection) {
                $0.paragraphFormat = newValue
            }
        }
    }
}
