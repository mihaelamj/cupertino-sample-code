/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Sales Details definitions.
*/

import Charts
import SwiftUI

struct DailySalesChart: View {
    @Binding var scrollPosition: Date

    var body: some View {
        Chart {
            ForEach(SalesData.last365Days, id: \.day) {
                BarMark(
                    x: .value("Day", $0.day, unit: .day),
                    y: .value("Sales", $0.sales)
                )
            }
            .foregroundStyle(.blue)
        }
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 3600 * 24 * 30)
        .chartScrollTargetBehavior(
            .valueAligned(
                matching: .init(hour: 0),
                majorAlignment: .matching(.init(day: 1))))
        .chartScrollPosition(x: $scrollPosition)

        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) {
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }
}

struct MonthlySalesChart: View {
    var body: some View {
        Chart(SalesData.last12Months, id: \.month) {
            BarMark(
                x: .value("Month", $0.month, unit: .month),
                y: .value("Sales", $0.sales)
            )
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

struct SalesDetails: View {
    @State private var timeRange: TimeRange = .last30Days
    @State var scrollPositionStart =
        SalesData.last365Days.last!.day.addingTimeInterval(-1 * 3600 * 24 * 30)

    var scrollPositionEnd: Date {
        scrollPositionStart.addingTimeInterval(3600 * 24 * 30)
    }
    
    var scrollPositionString: String {
        scrollPositionStart.formatted(.dateTime.month().day())
    }
    
    var scrollPositionEndString: String {
        scrollPositionEnd.formatted(.dateTime.month().day().year())
    }
                                 
    var body: some View {
        List {
            VStack(alignment: .leading) {
                TimeRangePicker(value: $timeRange)
                    .padding(.bottom)

                Text("Total Sales")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                switch timeRange {
                case .last30Days:
                    Text("\(SalesData.salesInPeriod(in: scrollPositionStart...scrollPositionEnd), format: .number) Pancakes")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    Text("\(scrollPositionString) – \(scrollPositionEndString)")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    DailySalesChart(scrollPosition: $scrollPositionStart)
                        .frame(height: 240)
                case .last12Months:
                    Text("\(SalesData.last12MonthsTotal, format: .number) Pancakes")
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    MonthlySalesChart()
                        .frame(height: 240)
                }
            }
            .listRowSeparator(.hidden)
            .transaction {
                $0.animation = nil // Do not animate between different sets of bars.
            }

            Section("More info") {
                TransactionsLink()
            }
        }
        .listStyle(.plain)
        #if !os(macOS)
        .navigationBarTitle("Total Sales", displayMode: .inline)
        #endif
        .navigationDestination(for: [Transaction].self) { transactions in
            TransactionsView(transactions: transactions)
        }
    }
}

#Preview {
    SalesDetails()
}
