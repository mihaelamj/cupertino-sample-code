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

struct Provider: AppIntentTimelineProvider {
    let modelContext = ModelContext(DataGeneration.container)
    
    init() {
        DataGeneration.generateAllData(modelContext: modelContext)
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    func recommendations() -> [AppIntentRecommendation<ConfigurationAppIntent>] {
        // Create an array with all the preconfigured widgets to show.
        [AppIntentRecommendation(intent: ConfigurationAppIntent(), description: "Example Widget")]
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
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

struct BackyardBirdsWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        HStack {
            Text("Time:")
            Text(entry.date, style: .time)
        }
        Text("Example Widget")
            .containerBackground(Color.black, for: .widget)
    }
}

