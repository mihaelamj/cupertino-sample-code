/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Sales Parameters definitions.
*/

import Charts
import SwiftUI

struct SalesMinMaxAverageChart: View {
    let showAverageLine: Bool

    var body: some View {
        Chart {
            ForEach(SalesData.last12Months, id: \.month) {
                BarMark(
                    x: .value("Month", $0.month, unit: .month),
                    yStart: .value("Min Sales", $0.dailyMin),
                    yEnd: .value("Max Sales", $0.dailyMax),
                    width: .ratio(0.6)
                )
                .opacity(0.3)
                RectangleMark(
                    x: .value("Month", $0.month, unit: .month),
                    y: .value("Sales", $0.dailyAverage),
                    width: .ratio(0.6),
                    height: .fixed(2)
                )
            }
            .foregroundStyle(showAverageLine ? .gray.opacity(0.5) : .blue)

            if showAverageLine {
                let average = SalesData.last12MonthsDailyAverage
                RuleMark(
                    y: .value("Average", average)
                )
                .foregroundStyle(.blue)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .annotation(position: .top, alignment: .leading) {
                    Text("Average: \(average, format: .number)")
                        .font(.body.bold())
                        .foregroundStyle(.blue)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.month(.narrow), centered: true)
            }
        }
    }
}

struct SalesMinMaxAverage: View {
    @State private var showAverageLine: Bool = false

    var body: some View {
        List {
            VStack(alignment: .leading) {
                Text("Average daily sales in the last 12 months")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text("\(SalesData.last12MonthsDailyAverage, format: .number) Pancakes")
                    .font(.title2.bold())

                SalesMinMaxAverageChart(showAverageLine: showAverageLine)
                    .frame(height: 240)
            }
            .listRowSeparator(.hidden)

            Section("Options") {
                Toggle("Show Daily Average", isOn: $showAverageLine)
                TransactionsLink()
            }
        }
        .listStyle(.plain)
        #if !os(macOS)
        .navigationBarTitle("Daily Average, Min, Max", displayMode: .inline)
        #endif
        .navigationDestination(for: [Transaction].self) { transactions in
            TransactionsView(transactions: transactions)
        }
    }
}

#Preview {
    SalesMinMaxAverage()
}
