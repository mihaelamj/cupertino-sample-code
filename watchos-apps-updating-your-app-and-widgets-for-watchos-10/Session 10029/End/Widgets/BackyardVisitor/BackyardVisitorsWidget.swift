/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
BackyardVisitorsWidget showing visitors to backyards.
*/

import WidgetKit
import SwiftUI
import BackyardBirdsUI
import BackyardBirdsData
import LayeredArtworkLibrary
import SwiftData
import OSLog
import AppIntents

struct Provider: AppIntentTimelineProvider {
    let modelContext = ModelContext(DataGeneration.container)
    
    init() {
        DataGeneration.generateAllData(modelContext: modelContext)
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), backyard: Backyard.anyBackyard(modelContext: modelContext))
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        if let backyard = Backyard.backyardForID(modelContext: modelContext, backyardID: configuration.backyardID) {
            if let event = backyard.visitorEvents.first {
                return SimpleEntry(date: event.startDate, configuration: configuration, backyard: backyard)
            } else {
                return SimpleEntry(date: Date(), configuration: configuration, backyard: backyard)
            }
        }

        let yard = Backyard.anyBackyard(modelContext: modelContext)
        return SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), backyard: yard)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        if let backyard = Backyard.backyardForID(modelContext: modelContext, backyardID: configuration.backyardID) {
            for event in backyard.visitorEvents {
                let entry = SimpleEntry(date: event.startDate, configuration: configuration, backyard: backyard)
                entries.append(entry)
                let afterEntry = SimpleEntry(date: event.endDate, configuration: configuration, backyard: backyard)
                entries.append(afterEntry)
            }
        }

        await updateBackyardRelevantIntents()
        return Timeline(entries: entries, policy: .atEnd)
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        var recs = [AppIntentRecommendation<ConfigurationAppIntent>]()

        for backyard in Backyard.allBackyards(modelContext: modelContext) {
            let configIntent = ConfigurationAppIntent()
            configIntent.backyardID = backyard.id.uuidString
            let gardenRecommendation = AppIntentRecommendation(intent: configIntent, description: backyard.name)
            recs.append(gardenRecommendation)
        }

        return recs
    }
}

struct SimpleEntry: TimelineEntry {
    var date: Date
    var configuration: ConfigurationAppIntent
    var backyard: Backyard
    
    var bird: Bird? {
        return backyard.visitorEventForDate(date: date)?.bird
    }
    
    var waterDuration: Duration {
        return Duration.seconds(abs(self.date.distance(to: self.backyard.waterRefillDate)))
    }

    var foodDuration: Duration {
        return Duration.seconds(abs(self.date.distance(to: self.backyard.foodRefillDate)))
    }

    var relevance: TimelineEntryRelevance? {
        if let visitor = backyard.visitorEventForDate(date: date) {
            return TimelineEntryRelevance(score: 10, duration: visitor.endDate.timeIntervalSince(date))
        }
        return nil
    }
}

struct BackyardBirdsWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: SimpleEntry
    
    var launchURL: String {
        return String(format: "backyardbirds://?backyardid=%@", entry.backyard.id.uuidString)
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularBackyardView(entry: entry)
                .widgetURL(URL(string: launchURL))
        case .accessoryRectangular:
            RectangularBackyardView(entry: entry)
                .widgetURL(URL(string: launchURL))
        case .accessoryInline:
            InlineBackgroundView(entry: entry)
                .widgetURL(URL(string: launchURL))
        case .accessoryCorner:
            CornerBackgroundView(entry: entry)
                .widgetURL(URL(string: launchURL))
        default:
            Text(entry.date, style: .time)
        }
    }
}

struct BackyardVisitorsWidget: Widget {
    let kind: String = "BackyardVisitorsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BackyardBirdsWidgetEntryView(entry: entry)
        }
    }
}

private var previewIntent: ConfigurationAppIntent {
    let modelContext = ModelContext(DataGeneration.container)

    DataGeneration.generateAllData(modelContext: modelContext)
    
    let backyard = try! modelContext.fetch(FetchDescriptor<Backyard>(sortBy: [.init(\.creationDate)])).first!
    let intent = ConfigurationAppIntent()
    intent.backyardID = backyard.id.uuidString
    return intent
}

private let _preview = Preview(as: .accessoryRectangular, using: previewIntent) {
    BackyardVisitorsWidget()
} timelineProvider: {
    Provider()
}
    
struct RectangularBackyardView: View {
    var entry: SimpleEntry
    
    var body: some View {
        HStack {
            if let bird = entry.bird {
                ComposedBird(bird: bird)
                    .scaledToFit()
                    .widgetAccentable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text(bird.speciesName)
                        .font(.headline)
                        .foregroundStyle(bird.colors.wing.color)
                        .widgetAccentable()
                        .minimumScaleFactor(0.75)
                    Text(entry.backyard.name)
                        .minimumScaleFactor(0.75)
                    HStack {
                        Image(systemName: "drop.fill")
                        Text(entry.waterDuration, format: remainingHoursFormatter)
                        Image(systemName: "fork.knife")
                        Text(entry.foodDuration, format: remainingHoursFormatter)
                    }
                    .imageScale(.small)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Image(.fountainFill)
                    .foregroundStyle(entry.backyard.backgroundColor)
                    .imageScale(.large)
                    .scaledToFit()
                    .widgetAccentable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text(entry.backyard.name)
                        .font(.headline)
                        .foregroundStyle(entry.backyard.backgroundColor)
                        .widgetAccentable()
                        .minimumScaleFactor(0.75)
                    HStack {
                        Image(systemName: "drop.fill")
                        Text(entry.waterDuration, format: remainingHoursFormatter)
                        Image(systemName: "fork.knife")
                        Text(entry.foodDuration, format: remainingHoursFormatter)
                    }
                    .imageScale(.small)
                    .minimumScaleFactor(0.75)
                    Text("\(entry.backyard.historicalEvents.count) visitors")
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .containerBackground(entry.backyard.backgroundColor.gradient, for: .widget)
    }
}
