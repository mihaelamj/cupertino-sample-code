/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The intent invocation phrases.
*/

import Foundation

public struct BackyardPhrases {
    static let delete = String(
        localized: "Delete Backyard",
        table: "Backyards",
        bundle: .module,
        comment: "Verb, an action that deletes a backyard."
    )
    
    static let rename = String(
        localized: "Rename Backyard",
        table: "Backyards",
        bundle: .module,
        comment: "Verb, an action that renames a backyard."
    )
    
    static let waterLow = String(
        localized: "Water Low",
        table: "Backyards",
        bundle: .module,
        comment: "A short phrase that describes an issue due to little water remaining."
    )
    
    static let foodLow = String(
        localized: "Food Low",
        table: "Backyards",
        bundle: .module,
        comment: "A short phrase that describes an issue due to little food remaining."
    )
    
    static let suppliesLow = String(
        localized: "Supplies Low",
        table: "Backyards",
        bundle: .module,
        comment: "A short phrase that describes an issue due to few supplies remaining."
    )
    
    static let waterEmpty = String(
        localized: "Water Empty",
        table: "Backyards",
        bundle: .module,
        comment: "A short phrase that describes an issue due to no water remaining."
    )
    
    static let foodEmpty = String(
        localized: "Food Empty",
        table: "Backyards",
        bundle: .module,
        comment: "A short phrase that describes an issue due to no food remaining."
    )
    
    static let suppliesEmpty = String(
        localized: "Supplies Empty",
        table: "Backyards",
        bundle: .module,
        comment: "A short phrase that describes an issue due to no supplies remaining."
    )
}
