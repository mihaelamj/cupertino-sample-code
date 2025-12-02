/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A widget that shows a leaderboard of all available heroes.
*/

import WidgetKit
import SwiftUI

struct LeaderboardProvider: TimelineProvider {
    
    public typealias Entry = LeaderboardEntry
    
    func placeholder(in context: Context) -> LeaderboardEntry {
        return LeaderboardEntry(date: Date(), heros: EmojiRanger.allHeros)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LeaderboardEntry) -> Void) {
        completion(LeaderboardEntry(date: Date(), heros: EmojiRanger.allHeros))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LeaderboardEntry>) -> Void) {
        Task {
            guard let heros = await EmojiRanger.loadLeaderboardData() else {
                completion(Timeline(entries: [LeaderboardEntry(date: Date(), heros: EmojiRanger.allHeros)], policy: .atEnd))
                return
            }
            completion(Timeline(entries: [LeaderboardEntry(date: Date(), heros: heros)], policy: .atEnd))
        }
    }
    
}

struct LeaderboardEntry: TimelineEntry {
    public let date: Date
    var heros: [EmojiRanger]?
}

struct LeaderboardPlaceholderView: View {
    var body: some View {
        LeaderboardWidgetEntryView(entry: LeaderboardEntry(date: Date(), heros: nil))
    }
}

struct LeaderboardWidgetEntryView: View {
    var entry: LeaderboardProvider.Entry
    
    var body: some View {
        AllCharactersView(heros: entry.heros)
            .padding()
            .widgetBackground()
    }
}

struct LeaderboardWidget: Widget {
    
    private static var supportedFamilies: [WidgetFamily] {
        return [.systemLarge, .systemExtraLarge]
    }
    
    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: EmojiRanger.LeaderboardWidgetKind, provider: LeaderboardProvider()) { entry in
            LeaderboardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Ranger Leaderboard")
        .description("See all the rangers.")
        .supportedFamilies(LeaderboardWidget.supportedFamilies)
    }
}

#if os(iOS)

#Preview("Leaderboard", as: .systemLarge, widget: {
    LeaderboardWidget()
}, timeline: {
    LeaderboardEntry(date: Date(), heros: nil)
})
#endif
