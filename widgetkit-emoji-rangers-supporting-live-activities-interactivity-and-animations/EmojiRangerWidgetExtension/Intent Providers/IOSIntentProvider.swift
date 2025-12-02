/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The iOS Intent Provider.
*/

import SwiftUI
import WidgetKit

struct AppIntentProvider: AppIntentTimelineProvider {
    
    typealias Entry = SimpleEntry
    
    typealias Intent = EmojiRangerSelection
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), relevance: nil, hero: .spouty)
    }
    
    func snapshot(for configuration: EmojiRangerSelection, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), relevance: nil, hero: .spouty)
    }
    
    func timeline(for configuration: EmojiRangerSelection, in context: Context) async -> Timeline<SimpleEntry> {
        let selectedCharacter = hero(for: configuration)
        let endDate = selectedCharacter.fullHealthDate
        let oneMinute: TimeInterval = 60
        var currentDate = Date()
        var entries: [SimpleEntry] = []
        
        while currentDate < endDate {
            let relevance = TimelineEntryRelevance(score: Float(selectedCharacter.healthLevel))
            let entry = SimpleEntry(date: currentDate, relevance: relevance, hero: selectedCharacter)
            currentDate += oneMinute
            entries.append(entry)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
    
    func hero(for configuration: EmojiRangerSelection) -> EmojiRanger {
        if let hero = configuration.hero {
            // Save the most recently selected hero to the app group.
            try? EmojiRanger.setLastSelectedHero(hero: hero)
            return hero
        }
        return .spouty
    }
    
    func recommendations() -> [AppIntentRecommendation<EmojiRangerSelection>] {
        []
    }
    
}
