/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The migrated App Intent.
*/

import Foundation
import AppIntents
import WidgetKit

struct EmojiRangerSelection: AppIntent, WidgetConfigurationIntent {
    
    static let intentClassName = "EmojiRangerSelectionIntent"
    
    static var title: LocalizedStringResource = "Emoji Ranger Selection"
    static var description = IntentDescription("Select Hero")
    
    @Parameter(title: "Selected Hero", default: EmojiRanger.cake, optionsProvider: EmojiRangerOptionsProvider())
    var hero: EmojiRanger?
    
    struct EmojiRangerOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [EmojiRanger] {
            EmojiRanger.allHeros
        }
    }
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct RangerQuery: DynamicOptionsProvider, EntityQuery {
    
    typealias Result = [EmojiRanger]
    
    func entities(for identifiers: [String]) async throws -> Result {
        EmojiRanger.allHeros.compactMap { ranger in
            identifiers.contains(ranger.id) ? ranger : nil
        }
    }
    
    func results() async throws -> Result {
        EmojiRanger.allHeros
    }
    
    func defaultResult() async -> EmojiRanger? {
        EmojiRanger.panda
    }
}
