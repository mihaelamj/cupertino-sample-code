/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The widget that shows a spending summary.
*/

import WidgetKit
import SwiftUI

@main
struct SpendingWidget: Widget {
    let kind: String = "com.myapp.spending-widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SpendingWidgetProvider()) { entry in
            SpendingWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Spending Widget")
    }
}

// MARK: - Timeline

struct SpendingEntry: TimelineEntry {
    let date: Date
    let total: Decimal
    
    var isPlaceholder = false
}

struct SpendingWidgetProvider: TimelineProvider {
    func getSnapshot(in context: Context, completion: @escaping @Sendable (SpendingEntry) -> Void) {
        // Create a widget with sample values for the widget picker.
        completion(SpendingEntry(date: .now, total: 27))
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<SpendingEntry>) -> Void) {
        // Fetch the total spending from storage.
        let weeklyTotal = Storage().weeklySpending
        
        // Create the widget entry and pass it to the completion.
        let date = Date.now
        let entry = SpendingEntry(date: date, total: weeklyTotal)
        
        let timeline = Timeline(entries: [entry], policy: .never)
        
        completion(timeline)
    }
    
    func placeholder(in context: Context) -> SpendingEntry {
        // Create a blank widget for when it's loading.
        SpendingEntry(date: .now, total: 0, isPlaceholder: true)
    }
}

// MARK: - View

struct SpendingWidgetView: View {
    var entry: SpendingEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Spend")
                .fontWeight(.medium)
            Spacer()
            HStack {
                Spacer()
                Text(formattedAmount)
                    .lineLimit(1)
                    .font(.title)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .minimumScaleFactor(0.5)
                    .padding(.vertical, 8)
                    .privacySensitive()
                Spacer()
            }
            .background(.fill.secondary)
            .cornerRadius(16)
            
            Spacer()
            Text("Updated \(formattedDate)")
                .font(.footnote)
                .foregroundStyle(.gray)
                .privacySensitive()
        }
    }
    
    var formattedAmount: String {
        // If you're showing a placeholder, display a blank value.
        guard !entry.isPlaceholder else { return " " }
        
        return entry.total.formatCompactCurrency()
    }
    
    var formattedDate: String {
        // If you're showing a placeholder, display a blank value.
        guard !entry.isPlaceholder else { return " " }
        
        return entry.date.formatCompactDate
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    SpendingWidget()
} timeline: {
    SpendingEntry(date: .now.addingTimeInterval(-86_400), total: 5.99)
    SpendingEntry(date: .now.addingTimeInterval(-3600), total: 100)
    SpendingEntry(date: .now.addingTimeInterval(-60), total: 100_000)
    SpendingEntry(date: .now, total: 0, isPlaceholder: true)
}
