/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view of the app.
*/

import SwiftUI
import Charts

func date(year: Int, month: Int, day: Int = 1, hour: Int) -> Date {
    Calendar.current.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? Date()
}

struct DailySales: Identifiable {
    let day: Date
    let sales: Int

    var id: Date { day }
}

let dailySales: [DailySales] = [
    .init(day: date(year: 2022, month: 6, day: 5, hour: 12), sales: 12),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 13), sales: 13),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 14), sales: 8),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 15), sales: 6),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 16), sales: 5),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 17), sales: 10),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 18), sales: 12),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 19), sales: 23),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 20), sales: 22),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 21), sales: 15),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 22), sales: 2),
    .init(day: date(year: 2022, month: 6, day: 5, hour: 23), sales: 0),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 0), sales: 0),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 1), sales: 0),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 2), sales: 0),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 3), sales: 0),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 4), sales: 0),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 5), sales: 0),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 6), sales: 1),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 7), sales: 4),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 8), sales: 12),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 9), sales: 24),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 10), sales: 20),
    .init(day: date(year: 2022, month: 6, day: 6, hour: 11), sales: 10)
]

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Sales")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("100 pancakes sold in the last 24 hours")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Chart(dailySales) {
                        BarMark(
                            x: .value("Day", $0.day, unit: .hour),
                            y: .value("Sales", $0.sales)
                        )
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.hour())
                        }
                    }
                    .frame(height: 80)
                }
            }
        }
    }
}
        
#Preview {
    ContentView()
}
