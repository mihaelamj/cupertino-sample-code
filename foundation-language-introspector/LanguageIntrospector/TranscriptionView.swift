/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The transcription view.
*/

import SwiftUI

struct TranscriptionView: View {
    let languageText: LanguageText
    
    private var language: Locale.Language {
        languageText.language
    }
    
    private var text: String {
        languageText.text
    }
    
    var body: some View {
        if language.script == .japanese {
            if let kanaTranscription = text.applyingTransform(.hiraganaToKatakana, reverse: false) {
                Text(kanaTranscription)
                    .font(.subheadline)
            }
        } else if language.script != .latin {
            let isHanLanguage = language.script == .hanSimplified || language.script == .hanTraditional
            let stringTransform: StringTransform = isHanLanguage ? .mandarinToLatin : .toLatin
            
            if let latinTranscription = text.applyingTransform(stringTransform, reverse: false) {
                Text(latinTranscription)
                    .font(.subheadline)
                    .italic()
            }
        }
    }
}

#Preview {
    TranscriptionView(languageText: LanguageText(language: Locale.Language(identifier: "hi"), text: "दीवानों को सलाम"))
}
