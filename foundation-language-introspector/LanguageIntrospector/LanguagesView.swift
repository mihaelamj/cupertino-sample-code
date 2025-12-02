/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for languages.
*/

import SwiftUI

struct LanguagesView: View {
    @State private var model = LanguagesModel()
    
    private var selectedLanguage: Locale.Language {
        model.selectedLanguageText.language
    }
    
    var body: some View {
        ScrollView {
            HeaderImage(name: "globe")
            
            VStack {
                Picker("", selection: $model.selectedIndex) {
                    ForEach(model.sortedLanguageTexts.indices, id: \.self) { index in
                        Text(Locale.current.localizedString(forIdentifier: model.sortedLanguageTexts[index].language.minimalIdentifier)!).tag(index)
                    }
                }
                
                Text(model.selectedLanguageText.text)
                    .font(.body)
                    .padding(.top, 10)
                    .multilineTextAlignment(.center)
                    .typesettingLanguage(model.selectedLanguageText.language)
                
                TranscriptionView(languageText: model.selectedLanguageText)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .typesettingLanguage(model.selectedLanguageText.language)

                MaximalIdentifierView(language: selectedLanguage)
                MinimalIdentifierView(language: selectedLanguage)
                
                if let script = selectedLanguage.script,
                   let scriptName = Locale.current.localizedString(forScriptCode: script.identifier) {
                    ScriptView(scriptName: scriptName)
                }
               
                CharacterDirectionView(language: selectedLanguage)
                LineLayoutDirectionView(language: selectedLanguage)
            }
            .opaqueBackground()
        }
    }
}
