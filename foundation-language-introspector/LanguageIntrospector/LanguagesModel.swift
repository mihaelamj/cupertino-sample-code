/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for languages.
*/

import SwiftUI

@MainActor
@Observable class LanguagesModel {
    var selectedIndex: Int
    
    var selectedLanguageText: LanguageText {
        sortedLanguageTexts[selectedIndex]
    }
    
    /// Return an array of languages and sort them using an array of locales. If unspecified, default to using preferred locales.
    private func sortedLanguages(_ languages: [Locale.Language], using localesToSortWith: [Locale] = Locale.preferredLocales) -> [Locale.Language] {
        var matchedLocales: [Locale.Language] = []
        for preferredLocale in localesToSortWith {
            for language in languages {
                if preferredLocale.language.isEquivalent(to: language)
                    || preferredLocale.language.hasCommonParent(with: language)
                    || preferredLocale.language.parent?.isEquivalent(to: language) ?? false
                    || language.parent?.isEquivalent(to: preferredLocale.language) ?? false {
                    matchedLocales.append(language)
                }
            }
        }
        return matchedLocales
    }
    
    var sortedLanguageTexts: [LanguageText] {
        let sortedLocales = sortedLanguages(languageTexts.map({ $0.language }))
        return languageTexts.sorted {
            let index0 = sortedLocales.firstIndex(of: $0.language)
            let index1 = sortedLocales.firstIndex(of: $1.language)
            if index0 != nil || index1 != nil {
                return index0 ?? Int.max < index1 ?? Int.max
            } else {
                return Locale.current.localizedString(forIdentifier: $0.language.minimalIdentifier)?
                    .localizedStandardCompare(Locale.current.localizedString(forIdentifier: $1.language.minimalIdentifier)!) == .orderedAscending
                
            }
        }
    }
    
    private var languageTexts: [LanguageText] {
        [
            LanguageText(language: Locale.Language(identifier: "ar"), text: "تحية للمجانين"),
            LanguageText(language: Locale.Language(identifier: "bn"), text: "পাগলদের প্রতি শ্রদ্ধা"),
            LanguageText(language: Locale.Language(identifier: "de"), text: "Ein Hoch auf die Verrückten"),
            LanguageText(language: Locale.Language(identifier: "en"), text: "Here’s to the crazy ones"),
            LanguageText(language: Locale.Language(identifier: "es"), text: "Brindemos por los locos"),
            LanguageText(language: Locale.Language(identifier: "fa"), text: "درود بر دیوانه‌ها"),
            LanguageText(language: Locale.Language(identifier: "fr"), text: "À ceux qui sont fous"),
            LanguageText(language: Locale.Language(identifier: "he"), text: "לחולי הרוח"),
            LanguageText(language: Locale.Language(identifier: "hi"), text: "दीवानों को सलाम"),
            LanguageText(language: Locale.Language(identifier: "id"), text: "Untuk para orang gila"),
            LanguageText(language: Locale.Language(identifier: "it"), text: "Un brindisi ai folli"),
            LanguageText(language: Locale.Language(identifier: "ja"), text: "クレイジーな人たちに乾杯"),
            LanguageText(language: Locale.Language(identifier: "ko"), text: "미친 사람들에게 건배"),
            LanguageText(language: Locale.Language(identifier: "pa-IN"), text: "ਪਾਗਲਾਂ ਨੂੰ ਸਲਾਮ"),
            LanguageText(language: Locale.Language(identifier: "pa-Aran-PK"), text: "پاگلاں نوں سلام"),
            LanguageText(language: Locale.Language(identifier: "pt"), text: "Um brinde aos loucos"),
            LanguageText(language: Locale.Language(identifier: "ru"), text: "Да здравствуют безумцы"),
            LanguageText(language: Locale.Language(identifier: "sw"), text: "Kwa wale wendawazimu, salamu"),
            LanguageText(language: Locale.Language(identifier: "th"), text: "แด่คนบ้าเหล่านั้น"),
            LanguageText(language: Locale.Language(identifier: "tr"), text: "Deli olanlara selam olsun"),
            LanguageText(language: Locale.Language(identifier: "vi"), text: "Dành cho những kẻ điên"),
            LanguageText(language: Locale.Language(identifier: "zh-Hans-CN"), text: "向那些疯狂的人致敬"),
            LanguageText(language: Locale.Language(identifier: "zh-Hant-TW"), text: "向那些瘋狂的人致敬"),
            LanguageText(language: Locale.Language(identifier: "ur"), text: "دیوانوں کو سلام")
        ]
    }
    
    init() {
        self.selectedIndex = 0
    }
}

/// A model for storing a language locale and a text.
struct LanguageText {
    var language: Locale.Language
    var text: String
    
    init(language: Locale.Language, text: String) {
        self.language = language
        self.text = text
    }
}
