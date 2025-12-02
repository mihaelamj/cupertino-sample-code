/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Reading activity list displayed from the Window > Activity menu item on macOS.
*/

import SwiftUI
import Charts

#if os(macOS)
struct ReadingActivityList: View {
    @ObservedObject var activity: ReadingActivity
    @State private var items: [ReadingActivityItem] = []
    @State private var selection: Set<ReadingActivityItem.ID> = []

    var body: some View {
        VStack {
            Chart(chartData) { item in
                LineMark(
                    x: .value("Date", item.entry.date),
                    y: .value("Progress", item.entry.progress)
                )
                .foregroundStyle(by: .value("Book", item.book.title))
            }
            .chartForegroundStyleScale(domain: items.map(\.book.title))
            .chartLegend(position: .bottom, alignment: .center, spacing: 20)
            .frame(minHeight: 240)
            .scenePadding()
            
            Table(items, selection: $selection) {
                TableColumn("Book") { item in
                    Text(item.book.title)
                }
                .width(min: 240)
                TableColumn("Date") { item in
                    Text(item.entry.date, style: .date)
                }
                .width(min: 120)
                TableColumn("Completion") { item in
                    Text(item.entry.progress, format: .percent)
                }
                .width(min: 60)
            }
            .onReceive(activity.entries) {
                items = $0.sorted(by: >)
            }
        }
    }
    
    var chartData: [ReadingActivityItem] {
        guard !selection.isEmpty else { return items }
        return items.filter { selection.map(\.bookId).contains($0.book.id) }
    }
}
#endif
