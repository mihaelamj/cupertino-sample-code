/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Locations Overview definitions.
*/

import Charts
import SwiftUI

struct LocationsOverviewChart: View {
    let symbolSize: CGFloat = 100
    let lineWidth: CGFloat = 3

    var body: some View {
        Chart {
            ForEach(LocationData.last30Days) { series in
                ForEach(series.sales, id: \.day) { element in
                    LineMark(
                        x: .value("Day", element.day, unit: .day),
                        y: .value("Sales", element.sales)
                    )
                }
                .foregroundStyle(by: .value("City", series.city))
                .symbol(by: .value("City", series.city))
            }
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: lineWidth))
            .symbolSize(symbolSize)

            PointMark(
                x: .value("Day", LocationData.last30DaysBest.weekday, unit: .day),
                y: .value("Sales", LocationData.last30DaysBest.sales)
            )
            .foregroundStyle(.purple)
            .symbolSize(symbolSize)
        }
        .chartForegroundStyleScale([
            "San Francisco": .purple,
            "Cupertino": .green
        ])
        .chartSymbolScale([
            "San Francisco": Circle().strokeBorder(lineWidth: lineWidth),
            "Cupertino": Square().strokeBorder(lineWidth: lineWidth)
        ])
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
            }
        }
        .chartYAxis(.hidden)
        .chartYScale(range: .plotDimension(endPadding: 8))
        .chartLegend(.hidden)
    }
}

struct LocationsOverview: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Day + Location with Most Sales")
                .foregroundStyle(.secondary)
            Text("Sundays in San Francisco")
                .font(.title2.bold())
            LocationsOverviewChart()
                .frame(height: 100)
        }
    }
}

/// A square symbol for charts.
struct Square: ChartSymbolShape, InsettableShape {
    let inset: CGFloat

    init(inset: CGFloat = 0) {
        self.inset = inset
    }

    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 1
        let minDimension = min(rect.width, rect.height)
        return Path(
            roundedRect: .init(x: rect.midX - minDimension / 2, y: rect.midY - minDimension / 2, width: minDimension, height: minDimension),
            cornerRadius: cornerRadius
        )
    }

    func inset(by amount: CGFloat) -> Square {
        Square(inset: inset + amount)
    }

    var perceptualUnitRect: CGRect {
        // The width of the unit rectangle (square). Adjust this to
        // size the diamond symbol so it perceptually matches with
        // the circle.
        let scaleAdjustment: CGFloat = 0.75
        return CGRect(x: 0.5 - scaleAdjustment / 2, y: 0.5 - scaleAdjustment / 2, width: scaleAdjustment, height: scaleAdjustment)
    }
}

#Preview {
    LocationsOverview()
        .padding()
}

