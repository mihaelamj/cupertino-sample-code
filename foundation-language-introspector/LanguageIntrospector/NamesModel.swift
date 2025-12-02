/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for names.
*/

import SwiftUI

@MainActor
@Observable class NamesModel {
    var selectedIndex: Int
    var selectedStyle: PersonNameComponentsFormatter.Style
    
    var selectedNameComponents: PersonNameComponents {
        names[selectedIndex]
    }
    
    var name: String {
        PersonNameComponentsFormatter.localizedString(from: selectedNameComponents, style: selectedStyle)
    }
    
    var abbreviatedName: String {
        PersonNameComponentsFormatter.localizedString(from: selectedNameComponents, style: .abbreviated)
    }
    
    var phoneticName: String {
        PersonNameComponentsFormatter.localizedString(from: selectedNameComponents, style: selectedStyle, options: .phonetic)
    }
    
    var names: [PersonNameComponents] {
        [
            // Arabic
            PersonNameComponents(familyName: "أسعد",
                                     givenName: "باسل"),
                
            // Chinese, Simplified
            PersonNameComponents(familyName: "吴",
                                     givenName: "菲",
                                     phoneticRepresentation: PersonNameComponents(familyName: "Wú",
                                                                                  givenName: "Fēi")),
                
            // Chinese, Traditional
            PersonNameComponents(familyName: "張",
                                     givenName: "雅婷",
                                     phoneticRepresentation: PersonNameComponents(familyName: "ㄓㄤˉ",
                                                                                  givenName: "ㄧㄚˇㄊㄧㄥˊ")),
                
            // English
            PersonNameComponents(familyName: "Doe",
                                     givenName: "Jane"),
                
            // Hindi
            PersonNameComponents(familyName: "प्रिया",
                                     givenName: "कुमारी"),
                
            // Japanese
            PersonNameComponents(familyName: "山田",
                                     givenName: "太郎",
                                     phoneticRepresentation: PersonNameComponents(familyName: "ヤマダ",
                                                                                  givenName: "タロウ")),
                
            // Thai
            PersonNameComponents(familyName: "โด",
                                     givenName: "เจน")
        ]
    }
    
    init() {
        self.selectedIndex = 2
        self.selectedStyle = .long
    }
}

extension PersonNameComponents {
    init(namePrefix: String? = nil,
         familyName: String? = nil,
         middleName: String? = nil,
         givenName: String? = nil,
         nameSuffix: String? = nil,
         nickname: String? = nil,
         phoneticRepresentation: PersonNameComponents? = nil) {
        self.init()
        self.namePrefix = namePrefix
        self.familyName = familyName
        self.middleName = middleName
        self.givenName = givenName
        self.nameSuffix = nameSuffix
        self.nickname = nickname
        self.phoneticRepresentation = phoneticRepresentation
    }
}
