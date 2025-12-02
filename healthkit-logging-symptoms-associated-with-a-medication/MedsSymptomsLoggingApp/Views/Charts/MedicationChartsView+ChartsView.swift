/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for the chart showing the medication dose event data for a selected medication.
*/

import SwiftUI
import Charts
import HealthKit

extension MedicationChartsView {

    /// A view that shows a series of content together.
    struct ChartsView: View {
        @Binding var dateConfiguration: DateConfiguration
        let chartSeries: [ChartSeries]

        init(dateConfiguration: Binding<DateConfiguration>, chartSeries: [ChartSeries]) {
            self._dateConfiguration = dateConfiguration
            self.chartSeries = chartSeries
        }

        var body: some View {
            VStack {
                Text("Doses taken per day")
                    .font(.title3.bold().weight(.medium))
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity, alignment: .leading)
                chartContent
                    .padding()
                    .padding([.leading], 20) // Additional padding for leading because the view has no axis.
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(uiColor: .quaternarySystemFill))
                    }
                    .onGeometryChange(for: Int.self) { proxy in
                        Int(proxy.size.width / 80) // 80 points per chart point.
                    } action: { newValue in
                        dateConfiguration.aggregationBinCount = newValue
                    }
                DateIntervalPaginationView(dateConfiguration: $dateConfiguration)
                    .padding()
            }
        }

        @ViewBuilder
        private var chartContent: some View {
            Chart {
                ForEach(chartSeries) { series in
                    if let chartPoints = series.chartPoints {
                        ForEach(chartPoints) { $0.ruleMark }
                            .lineStyle(StrokeStyle(lineWidth: 20, lineCap: .round))
                            .foregroundStyle(Color.blue)
                    }
                }
            }
            .frame(minWidth: 80)
            .chartXScale(domain: [dateConfiguration.chartingDateInterval.start,
                                  dateConfiguration.chartingDateInterval.end],
                         range: .plotDimension(padding: 20)) // Show the dates for the data query.
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: dateConfiguration.dateBins.count))
            }
            .chartYScale(range: .plotDimension(padding: 20))
            .chartYAxis {
                AxisMarks(values: [1, 2, 3, 4]) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .contentTransition(.interpolate)
            .animation(.default, value: chartSeries)
        }
    }

    /// Contains the collection of points for a chart.
    struct ChartSeries: Identifiable, Equatable, Hashable {
        var id: HKHealthConceptIdentifier { medicationConcept.id }

        let medicationConcept: AnnotatedMedicationConcept
        let chartPoints: [ChartPoint]?

        init(medicationConcept: AnnotatedMedicationConcept,
             samples: [HKMedicationDoseEvent],
             dateConfiguration: DateConfiguration) {
            self.medicationConcept = medicationConcept
            self.chartPoints = Self.chartPoints(from: samples, dateBins: dateConfiguration.dateBins)
        }

        /// Returns an array of `ChartPoint` objects for a given collection of `HKMedicationDoseEvent` samples.
        private static func chartPoints(from samples: [HKMedicationDoseEvent], dateBins: DateBins) -> [ChartPoint] {
            // Group the samples by date.
            let groupedSamples = Dictionary(grouping: samples, by: { sample in
                dateBins.index(for: sample.endDate)
            })

            // Create a chart point for each day, and pin it to the start date of each bin to place it in the bin.
            let chartPoints = groupedSamples.map { chartPoint(for: $0.value, date: dateBins[$0.key].lowerBound) }
            return chartPoints
        }

        /// Returns a `ChartPoint` for a given collection of `HKMedicationDoseEvent` samples.
        private static func chartPoint(for sampleCollection: [HKMedicationDoseEvent], date: Date) -> ChartPoint {
            let doses = sampleCollection.map { $0.logStatus == .taken }
            return .init(xValue: date, yStart: Double(doses.count), yEnd: Double(doses.count))
        }
    }

    struct ChartPoint: Identifiable, Equatable, Hashable {
        var id: Date { xValue }
        let xValue: Date
        let yStart: Double
        let yEnd: Double

        var ruleMark: RuleMark {
            .init(x: .value("Date", xValue),
                  yStart: .value("Start", yStart),
                  yEnd: .value("End", yEnd))
        }

        init(xValue: Date,
             yStart: Double,
             yEnd: Double) {
            self.xValue = xValue
            self.yStart = yStart
            self.yEnd = yEnd
        }
    }

    /// A view that displays the date intervals with options to increment or decrement them.
    private struct DateIntervalPaginationView: View {
        @Binding var dateConfiguration: DateConfiguration
        var configurationContainsCurrentDate: Bool {
            dateConfiguration.chartingDateInterval.contains(Calendar.current.startOfDay(for: Date()))
        }

        var body: some View {
            HStack {
                Button {
                    dateConfiguration.decrement()
                } label: {
                    Image(systemName: "arrow.backward.circle")
                }
                .buttonStyle(.plain)
                dateIntervalText.frame(minWidth: 100) // Prevent buttons from moving as the text size changes.
                Button {
                    dateConfiguration.increment()
                } label: {
                    Image(systemName: "arrow.forward.circle")
                }
                .buttonStyle(.plain)
                .disabled(configurationContainsCurrentDate)
            }
        }

        @ViewBuilder
        var dateIntervalText: some View {
            // Use the start of the day to be exclusive of the end of the week.
            let startOfDay = Calendar.current.startOfDay(for: dateConfiguration.chartingDateInterval.start)
            let startString = DateFormatter.chartDateFormatter.string(for: startOfDay)!
            let endOfDay = Calendar.current.startOfDay(for: dateConfiguration.chartingDateInterval.end)
            let endString = DateFormatter.chartDateFormatter.string(for: endOfDay)!
            Text("\(startString) - \(endString)")
                .font(.title3)
                .bold()
        }
    }
}
