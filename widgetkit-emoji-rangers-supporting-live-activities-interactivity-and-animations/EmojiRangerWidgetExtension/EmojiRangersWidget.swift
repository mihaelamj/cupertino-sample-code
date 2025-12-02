/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A widget that shows the avatar for a single hero.
*/

import WidgetKit
import SwiftUI

#if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)

@available(iOSApplicationExtension 18.0, *)
struct EmojiRangerControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: "com.emoji-rangers.control", intent: SuperCharge.self) { config in
            ControlWidgetButton(action: config) {
                Image(systemName: "bolt\(EmojiRanger.herosAreSupercharged() ? ".fill" : "")")
            }
        }
    }
}

#endif

struct SimpleEntry: TimelineEntry {
    public let date: Date
    let relevance: TimelineEntryRelevance?
    let hero: EmojiRanger
}

struct PlaceholderView: View {
    var body: some View {
        EmojiRangerWidgetEntryView(entry: SimpleEntry(date: Date(), relevance: nil, hero: .spouty))
    }
}

extension View {
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                Color.gameBackgroundColor
            }
        } else {
            return background {
                Color.gameBackgroundColor
            }
        }
    }
}

struct EmojiRangerWidgetEntryView: View {
    var entry: SimpleEntry
    
    @Environment(\.widgetFamily) var family
    
    @AppStorage("supercharged", store: EmojiRanger.emojiDefaults)
    var supercharged: Bool = EmojiRanger.herosAreSupercharged()
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            ProgressView(timerInterval: entry.hero.injuryDate...entry.hero.fullHealthDate,
                         countsDown: false,
                         label: { Text(entry.hero.name) },
                         currentValueLabel: {
                Avatar(hero: entry.hero, includeBackground: false)
            })
            .progressViewStyle(.circular)
            .widgetBackground()
            
        case .accessoryRectangular:
            HStack(alignment: .center, spacing: 0) {
                VStack(alignment: .leading) {
                    Text(entry.hero.name)
                        .font(.headline)
                        .widgetAccentable()
                    Text("Level \(entry.hero.level)")
                    Text(entry.hero.fullHealthDate, style: .timer)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Avatar(hero: entry.hero, includeBackground: false)
            }
            .widgetBackground()
            
        case .accessoryInline:
            ViewThatFits {
                Text("\(entry.hero.name) is healing, ready in \(entry.hero.fullHealthDate, style: .relative)")
                Text("\(entry.hero.name) ready in \(entry.hero.fullHealthDate, style: .relative)")
                Text("\(entry.hero.name) \(entry.hero.fullHealthDate, style: .timer)")
            }
            .widgetBackground()
            
        case .systemSmall:
            AvatarView(entry.hero)
                .foregroundStyle(.white)
                .widgetBackground()
                .widgetURL(entry.hero.url)
            
        case .systemLarge:
            VStack {
                HStack(alignment: .top) {
                    AvatarView(entry.hero)
                        .foregroundStyle(.white)
                    Text(entry.hero.bio)
                        .foregroundStyle(.white)
                }
                .padding()
#if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
                Button(intent: SuperCharge()) {
                    Text("⚡️")
                        .lineLimit(1)
                }
#endif
            }
            .widgetBackground()
            .widgetURL(entry.hero.url)
        case .systemMedium:
            HStack(alignment: .top) {
                AvatarView(entry.hero)
                    .foregroundStyle(.white)
                Text(entry.hero.bio)
                    .foregroundStyle(.white)
            }
            .widgetBackground()
            .widgetURL(entry.hero.url)
        default:
            AvatarView(entry.hero)
        }
        
    }
}

struct EmojiRangerWidget: Widget {
    
    func makeWidgetConfiguration() -> some WidgetConfiguration {
#if os(watchOS)
        return AppIntentConfiguration(kind: EmojiRanger.EmojiRangerWidgetKind,
                                      intent: EmojiRangerSelection.self,
                                      provider: AppIntentProvider()) { entry in
            EmojiRangerWidgetEntryView(entry: entry)
        }
                                      .supportedFamilies(supportedFamilies)
#else
        return AppIntentConfiguration(kind: EmojiRanger.EmojiRangerWidgetKind,
                                      intent: EmojiRangerSelection.self,
                                      provider: AppIntentProvider()) { entry in
            EmojiRangerWidgetEntryView(entry: entry)
        }
                                      .supportedFamilies(supportedFamilies)
#endif
    }
    
    private var supportedFamilies: [WidgetFamily] {
#if os(watchOS)
        [.accessoryCircular,
         .accessoryRectangular, .accessoryInline]
#else
        [.accessoryCircular,
         .accessoryRectangular, .accessoryInline,
         .systemSmall, .systemMedium, .systemLarge]
#endif
    }
    
    public var body: some WidgetConfiguration {
        makeWidgetConfiguration()
            .configurationDisplayName("Ranger Detail")
            .description("See your favorite ranger.")
    }
}

#if os(iOS) || os(macOS) || targetEnvironment(macCatalyst)
#Preview(as: .systemMedium, widget: {
    EmojiRangerWidget()
}, timeline: {
    let date = Date()
    SimpleEntry(date: date, relevance: nil, hero: .spouty)
    SimpleEntry(date: date.addingTimeInterval(60), relevance: nil, hero: .spook)
})
#endif
