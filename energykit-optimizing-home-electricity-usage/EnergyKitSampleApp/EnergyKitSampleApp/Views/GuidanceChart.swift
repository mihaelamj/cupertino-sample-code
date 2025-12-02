/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A bar chart that displays energy guidance for the given energy venue.
*/

import Charts
import EnergyKit
import SwiftUI

/// A bar chart that displays energy guidance for the given energy venue.
struct GuidanceChart: View {
    var guidance: ElectricityGuidance

    @State var selectedTime: Date?

    var guidanceForTime: ElectricityGuidance.Value? {
        if let selectedTime {
            if let value = guidance.values.first(
                where: { selectedTime >= $0.interval.start && selectedTime < $0.interval.start.addingTimeInterval($0.interval.duration) }
            ) {
                return value
            }
        }
        return nil
    }

    var body: some View {
        let selectedValue = guidanceForTime
        VStack {
            if let first = guidance.values.first, let last = guidance.values.last {
                guidanceDescription(firstValue: first, lastValue: last)
                    .opacity(selectedValue == nil ? 1.0 : 0.0)
            }

            Chart {
                // Selection view.
                if let selectedValue {
                    guidanceAnnotationFor(value: selectedValue)
                }

                BarPlot(
                    guidance.values,
                    xStart: .value("Time", \.interval.start),
                    xEnd: .value("Time", \.interval.end),
                    y: .value("Guidance", \.rating)
                )
                .foregroundStyle(by: .value("Value", \.rating))
            }
            .aspectRatio(contentMode: .fit)
            .chartYScale(domain: 0.0...1.0)
            .chartXSelection(value: $selectedTime)
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                    AxisValueLabel(format: .dateTime.hour())
                    AxisGridLine()
                    AxisTick()
                }
            }
        }
    }

    /// Provides the guidance description.
    func guidanceDescription(firstValue: ElectricityGuidance.Value, lastValue: ElectricityGuidance.Value) -> some View {
        VStack {
            AttributeValueTextView(attribute: "Start Time:", value: "\(firstValue.interval.start.formatted(.dateTime.month().day().hour().minute()))")

            AttributeValueTextView(attribute: "End Time:", value: "\(lastValue.interval.end.formatted(.dateTime.month().day().hour().minute()))")

            let timeSpanValueStr = String(format: "%.2f", (guidance.interval.duration / 3600))

            // The horizon of the guidance forecast in hours
            AttributeValueTextView(attribute: "Time Horizon [hours]:", value: timeSpanValueStr)

            // The total number of data points this guidance forecast has
            AttributeValueTextView(attribute: "Total Samples:", value: "\(guidance.values.count)")
        }
    }

    /// Provides the thermostat annotation for selected value.
    @ChartContentBuilder
    func guidanceAnnotationFor(value: ElectricityGuidance.Value) -> some ChartContent {
        RuleMark(x: .value("selected time", selectedTime!, unit: .minute))
            .foregroundStyle(Color.gray.opacity(0.3))
            .offset(yStart: -11)
            .annotation(
                position: .top,
                spacing: 0,
                overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                guidanceInfo(for: value)
                .padding(6)
                .background {
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundStyle(Color.gray.opacity(0.3))
                }
            }
    }

    /// Provides the guidance information as annotation for the selected value.
    func guidanceInfo(for value: ElectricityGuidance.Value) -> some View {
        VStack(alignment: .leading) {
            Text("RATING").font(.subheadline)
            Text("\(value.rating, specifier: "%.2f")")
                .font(.title).bold()
            HStack(spacing: 0) {
                Text(guidance.values.first!.interval.start.formatted(.dateTime.month().day()))

                selectedTime.map {
                    Text(", \($0.formatted(.dateTime.hour().minute()))")
                } ?? Text("")
            }
            .font(.subheadline)
            .bold()
        }
    }
}
