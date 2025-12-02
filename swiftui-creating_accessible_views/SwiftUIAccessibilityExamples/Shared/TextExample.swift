/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Text-related accessibility examples.
*/

import SwiftUI

/// Examples of making Text accessible using SwiftUI.
struct TextExample: View {
    var body: some View {
        LabeledExample("Text Accessibility") {
            Text("This text will have a different label for Accessibility")
                .accessibilityLabel("Accessibility Label")

            VStack(alignment: .leading) {
                Text("Stacked Multiple Line Text Line 1")
                Text("This is on another line")
                Text("This will be a single Accessibility element.")
                Text("Because of the `.combine` modifier.")
            }
            .accessibilityElement(children: .combine)

            Text("This Text will have both an Label and Value for Accessibility")
                // Prefer `accessibilityLabel` for aspects of accessibility
                // elements that identify the element to the user,
                // such as the name of the setting being changed by a switch control.
                .accessibilityLabel("Text Label")
                // Prefer `accessibilityValue` for aspects of accessibility
                // elements that can change, such as the current state of
                // controls, like whether a switch is currently on or off.
                .accessibilityValue("Text Value")
        }

        LabeledExample("Text with VoiceOver Customization") {
            Text("This text will spell out characters")
                .speechSpellsOutCharacters()

            Text(AttributedString("This text will never spell out characters") {
                $0.accessibilitySpeechSpellsOutCharacters = false
            })

            Text("The text will be spoken at a high pitch")
                .speechAdjustedPitch(1)

            Text(AttributedString("The text will be spoken at a low pitch") {
                $0.accessibilitySpeechAdjustedPitch = -1
            })

            Text("This text will, always, completely spell out punctuation!")
                .speechAlwaysIncludesPunctuation()

            Text(AttributedString("This text will never spell out punctuation!") {
                $0.accessibilitySpeechIncludesPunctuation = false
            })

            Text("This text will be spoken behind existing speech in VoiceOver")
                .speechAnnouncementsQueued(true)
        }

        LabeledExample("Customizing Pronunciation") {
            // Use speechPhoneticRepresentation` to specify pronunciation
            // of the text by VoiceOver in IPA notation.
            Text(AttributedString("Record") {
                $0.accessibilitySpeechPhoneticNotation = "ɹɪˈkɔɹd"
            })
            Text(AttributedString("Record") {
                $0.accessibilitySpeechPhoneticNotation = "ˈɹɛkɚd"
            })
        }

        // Use accessibilityTextContentType to specify what kind of content your
        // text includes, to allow VoiceOver to better interact with it.
        LabeledExample("Text Content Types") {
            Text("this_text_will_be_treated_as_source_code")
                .accessibilityTextContentType(.sourceCode)

            Text("This text will be treated as if it was in a Word Processing document.")
                .accessibilityTextContentType(.wordProcessing)

            Text(AttributedString("This text will be treated as if it was in a narrative") {
                $0.accessibilityTextualContext = .narrative
            })
        }

        // Use the accessibilityHeading modifier or the isHeader trait to mark
        // headings in your text. You can use up to six levels of headings
        // which can be navigated separately.
        LabeledExample("Headings") {
            Text("This will be a standard heading")
                .bold()
                .accessibilityHeading(.unspecified)
            Text("This will be a level-one heading")
                .italic()
                .accessibilityHeading(.h1)
            Text("This will be a level-two heading")
                .underline()
                .accessibilityHeading(.h2)
            Text("This will be another a standard heading")
                .bold()
                .accessibilityHeading(.unspecified)
            Text("This will be a third standard heading")
                .bold()
                .accessibilityAddTraits(.isHeader)

            Text(AttributedString("This will be a level-one heading") {
                $0.accessibilityHeadingLevel = .h1
            })
        }

        LabeledExample("Custom") {
            Text(AttributedString("This has custom attributes, spoken by VoiceOver") {
                $0.accessibilityTextCustom = ["Custom description"]
            })
        }
    }
}

extension AttributedString {
    init(_ string: String, configuration: (inout AttributedString) -> Void) {
        var attrString = AttributedString(string)
        configuration(&attrString)
        self = attrString
    }
}
