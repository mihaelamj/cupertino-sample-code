/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view for the sleep cell.
*/

import SwiftUI
import Charts

struct SleepSample: Identifiable {
    let id: UUID
    var date: Date
    var startMinute: Int
    var totalMinutes: Int
    var durationHours: Int {
        totalMinutes / 60
    }
    var durationMinutes: Int {
        totalMinutes % 60
    }
}

struct SleepData {
    var samples = [SleepSample]()
    var latestSample: SleepSample {
        samples.first!
    }
}

struct SleepCellView: View {
    var data: SleepData
    
    var body: some View {
        VStack(alignment: .leading) {
            SleepChartView(sleepSamples: data.samples)
            SleepTimeInBedView(latestSample: data.latestSample)
        }
    }
}

struct SleepChartView: View {
    var sleepSamples: [SleepSample]
    
    var body: some View {
        Chart(sleepSamples) { sample in
            RuleMark(x: .value("date", sample.date),
                     yStart: .value("Start", sample.startMinute),
                     yEnd: .value("End", sample.startMinute + sample.totalMinutes))
            .foregroundStyle(.teal)
            .lineStyle(.init(lineWidth: 10, lineCap: .round))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .padding(.horizontal, 6)
        .padding(.top)
        .padding(.bottom, 4)
        .frame(height: 60)
    }
}

struct SleepTimeInBedView: View {
    var latestSample: SleepSample
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Time in Bed")
                .foregroundStyle(.secondary)
                .font(.system(.footnote, weight: .bold))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                HourMinuteView(value: latestSample.durationHours, unit: "h")
                HourMinuteView(value: latestSample.durationMinutes, unit: "m")
            }
        }
    }
}

struct HourMinuteView: View {
    var value: Int
    var unit: String
    
    var body: some View {
        Text(value, format: .number)
            .foregroundStyle(.primary)
            .font(.system(.title2, weight: .semibold))
        Text(unit)
            .foregroundStyle(.secondary)
            .font(.system(.footnote, weight: .bold))
    }
}

extension SleepData {
    static func generateRandomData(quantity: Int) -> [SleepData] {
        var data = [SleepData]()
        for _ in 0..<quantity {
            var sleepData = SleepData()
            let today = Date()
            for index in 0...8 {
                let date = Calendar.current.date(byAdding: .day, value: -index, to: today)!
                let start = Int.random(in: 20...23) * 60 + Int.random(in: 0...59)
                let duration = Int.random(in: 6...9) * 60 + Int.random(in: 0...59)
                let sample = SleepSample(id: UUID(), date: date, startMinute: start, totalMinutes: duration)
                sleepData.samples.append(sample)
            }
            data.append(sleepData)
        }
        return data
    }
}

struct SleepCellView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            SleepCellView(data: SleepData())
        }
    }
}
