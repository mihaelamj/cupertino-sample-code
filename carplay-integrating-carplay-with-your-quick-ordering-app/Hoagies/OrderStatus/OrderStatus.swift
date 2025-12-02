/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods that manage the widget and its life cycle.
*/

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> HoagieOrderEntry {
        HoagieOrderEntry(
            date: Date(),
            state: .init(isPickedUp: false, isReady: false, isPreparing: false, isConfirmed: true))
    }

    func getSnapshot(in context: Context, completion: @escaping (HoagieOrderEntry) -> Void) {
        completion(HoagieOrderEntry(
            date: Date(),
            state: .init(isPickedUp: false, isReady: false, isPreparing: false, isConfirmed: true)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HoagieOrderEntry>) -> Void) {
        completion(Timeline(entries: [
            HoagieOrderEntry(date: Date(),
                             state: OrderingService.service.orderState)], policy: .atEnd))
    }
}

struct HoagieOrderEntry: TimelineEntry {
    let date: Date
    let state: OrderStatusAttributes.ContentState
}

struct OrderStatusEntryView: View {
    var entry: Provider.Entry
    var body: some View {
        OrderStatusView(state: entry.state)
    }
}

struct OrderStatus: Widget {
    let kind: String = "OrderStatus"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                OrderStatusEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                OrderStatusEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .supportedFamilies([.systemMedium])
        .configurationDisplayName("Order Status")
        .description("The Order status is shown here. ✅ denotes a completed step.")
    }
}

