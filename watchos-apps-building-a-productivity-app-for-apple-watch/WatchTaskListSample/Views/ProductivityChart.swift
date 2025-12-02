/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A chart to display the number of completed items each day.
*/

import Charts
import SwiftUI

struct ProductivityChart: View {
    /// This is some sample data to show a two-week chart. To use your own data,
    /// use ChartData.createData(_: [ListItem]) with the data in the model.
    let data = ChartData.chartSampleData

    /// The index of the highlighted chart value. This is for crown scrolling.
    @State private var highlightedDateIndex: Int = 0

    /// The current offset of the crown while it's rotating. This sample sets the offset with
    /// the value in the DigitalCrownEvent and uses it to show an intermediate
    /// (between detents) chart value in the view.
    @State private var crownOffset: Double = 0.0

    @State private var isCrownIdle = true

    @State var crownPositionOpacity: CGFloat = 0.2

    @State var chartDataRange = (0...6)

    private var shortDateFormatStyle = DateFormatStyle(dateFormatTemplate: "Md")

    private func updateChartDataRange() {
        if (highlightedDateIndex - chartDataRange.lowerBound) < 2, chartDataRange.lowerBound > 0 {
            let newLowerBound = max(0, chartDataRange.lowerBound - 1)
            let newUpperBound = min(newLowerBound + 6, data.count - 1)
            chartDataRange = (newLowerBound...newUpperBound)
            return
        }
        if (chartDataRange.upperBound - highlightedDateIndex) < 2, chartDataRange.upperBound < data.count - 1 {
            let newUpperBound = min(chartDataRange.upperBound + 1, data.count - 1)
            let newLowerBound = max(0, newUpperBound - 6)
            chartDataRange = (newLowerBound...newUpperBound)
            return
        }
    }

    private var chartData: [ChartData.DataElement] {
        Array(data[chartDataRange.clamped(to: (0...data.count - 1))])
    }

    private func isLastDataPoint(_ dataPoint: ChartData.DataElement) -> Bool {
        data[chartDataRange.upperBound].id == dataPoint.id
    }

    private var chart: some View {
        Chart(chartData) { dataPoint in
            BarMark(x: .value("Date", dataPoint.date, unit: .day),
                    y: .value("Completed", dataPoint.itemsComplete))
            .foregroundStyle(Color.accentColor)
            .annotation(
                position: isLastDataPoint(dataPoint) ? .topLeading : .topTrailing,
                spacing: 0
            ) {
                Text("\(dataPoint.itemsComplete, format: .number)")
                    .foregroundStyle(dataPoint.date == crownOffsetDate ? Color.appYellow : Color.clear)
            }

            RuleMark(x: .value("Date", crownOffsetDate, unit: .day))
                .foregroundStyle(Color.appYellow.opacity(crownPositionOpacity))
        }
        .chartXAxis {
            AxisMarks(format: shortDateFormatStyle)
        }
    }

    /// The date value that corresponds to the crown offset.
    private var crownOffsetDate: Date {
        let dateDistance = data[0].date.distance(
            to: data[data.count - 1].date) * (crownOffset / Double(data.count - 1))
        return data[0].date.addingTimeInterval(dateDistance)
    }

    var body: some View {
        chart
            .focusable()
            .digitalCrownRotation(
                detent: $highlightedDateIndex,
                from: 0,
                through: data.count - 1,
                by: 1,
                sensitivity: .medium
            ) { crownEvent in
                isCrownIdle = false
                crownOffset = crownEvent.offset
            } onIdle: {
                isCrownIdle = true
            }
            .onChange(of: isCrownIdle) { newValue in
                withAnimation(newValue ? .easeOut : .easeIn) {
                    crownPositionOpacity = newValue ? 0.2 : 1.0
                }
            }
            .onChange(of: highlightedDateIndex) { newValue in
                withAnimation {
                    updateChartDataRange()
                }
            }
            .padding(.bottom, 15)
            .padding(.horizontal, 7)
            .edgesIgnoringSafeArea(.bottom)
            .navigationTitle("Productivity")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ProductivityChart_Previews: PreviewProvider {
    static var previews: some View {
        ProductivityChart()
    }
}
