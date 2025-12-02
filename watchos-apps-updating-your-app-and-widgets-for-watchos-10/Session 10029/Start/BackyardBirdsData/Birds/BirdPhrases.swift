/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Phrases.
*/

import Foundation

public struct BirdPhrases {
    static let recentBackyards = String(
        localized: "Recent Backyards",
        table: "Birds",
        bundle: .module,
        comment: "A section header title for showing which backyards a bird has visited."
    )
    
    static let nickNamePlaceholder = String(
        localized: "Nickname",
        table: "Birds",
        bundle: .module,
        comment: "A placeholder value that indicates this text field represents a bird's nickname."
    )
    
    static let nickName = String(
        localized: "Nickname",
        table: "Birds",
        bundle: .module,
        comment: "A label that describes a nickname of a bird; for example, Cutie."
    )
    
    static let isFavorite = String(
        localized: "Favorite",
        table: "Birds",
        bundle: .module,
        comment: "Verb, a control to toggle whether someone selects (or deselects) a bird as one of their favorites."
    )
}
