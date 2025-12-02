/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A watchOS widget that shows a colored timestamp from the companion iOS app.
*/

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        return SimpleEntry.placeholderEntry
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry.placeholderEntry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var timestamp = "No data"
        var color: UIColor = .white
        
        // Use the values from the app group container, if any.
        //
        if let sharedUserDefaults = UserDefaults(suiteName: WidgetSupport.appGroupContainer) {
            if let userDefaultsValue = sharedUserDefaults.string(forKey: WidgetSupport.UserDefaultsKey.timestamp) {
                timestamp = userDefaultsValue
            }
            if let colorData = sharedUserDefaults.data(forKey: WidgetSupport.UserDefaultsKey.colorData),
               let uiColor = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: colorData) as? UIColor {
                color = uiColor
            }
        }
        let entries = [SimpleEntry(date: .now, timestamp: timestamp, color: color)]
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let timestamp: String
    let color: UIColor
    
    static var placeholderEntry: SimpleEntry {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        let timestamp = dateFormatter.string(from: Date())
        return SimpleEntry(date: .now, timestamp: timestamp, color: .yellow)
    }

}

struct SimpleWatchWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("SimpleWatchWidget")
                .foregroundColor(.gray)
            Text("")
            Text(entry.timestamp)
                .font(.system(.title3).weight(.semibold))
                .foregroundColor(Color(uiColor: entry.color))
        }
        .minimumScaleFactor(0.4)
    }
}

@main
struct SimpleWatchWidget: Widget {
    let kind: String = WidgetSupport.widgetKind

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SimpleWatchWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("SWC")
        .description("This is an example widget.")
        .supportedFamilies([.accessoryRectangular])
    }
}

#Preview(as: .accessoryRectangular) {
    SimpleWatchWidget()
} timeline: {
    let entry1 = SimpleEntry.placeholderEntry
    SimpleEntry(date: .now, timestamp: entry1.timestamp, color: entry1.color)
}
