/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view for the heart rate cell.
*/

import SwiftUI
import Charts

struct HeartRateSample: Identifiable {
    let id: UUID
    var time: Date
    var beatsPerMinute: Int
}

struct HeartRateData {
    var samples = [HeartRateSample]()
    var latestSample: HeartRateSample {
        samples.first!
    }
}

struct HeartRateCellView: View {
    var data: HeartRateData
    
    var body: some View {
        VStack(alignment: .leading) {
            HeartRateTitleView(time: data.latestSample.time)
            HStack(alignment: .bottom) {
                HeartRateBPMView(latestSample: data.latestSample)
                Spacer(minLength: 60)
                HeartRateChartView(heartRateSamples: data.samples)
            }
        }
        .padding(.vertical, 8)
    }
}

struct HeartRateTitleView: View {
    var time: Date
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Label("Heart Rate", systemImage: "heart.fill")
                .foregroundStyle(.pink)
                .font(.system(.subheadline, weight: .bold))
                .layoutPriority(1)
            Spacer()
            Text(time, style: .time)
                .foregroundStyle(.secondary)
                .font(.footnote)
        }
    }
}

struct HeartRateBPMView: View {
    var latestSample: HeartRateSample
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(latestSample.beatsPerMinute, format: .number)
                .foregroundStyle(.primary)
                .font(.system(.title, weight: .semibold))
            Text("BPM")
                .foregroundStyle(.secondary)
                .font(.system(.subheadline, weight: .bold))
        }
    }
}

struct HeartRateChartView: View {
    var heartRateSamples: [HeartRateSample]
    
    var body: some View {
        Chart(heartRateSamples) { sample in
            LineMark(x: .value("Time", sample.time),
                     y: .value("Beats Per Minute", sample.beatsPerMinute))
            .symbol(Circle().strokeBorder(lineWidth: 2))
            .symbolSize(CGSize(width: 6, height: 6))
            .foregroundStyle(.pink)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: .automatic(includesZero: false))
        .padding(.vertical, 8)
    }
}

extension HeartRateData {
    static func generateRandomData(quantity: Int) -> [HeartRateData] {
        var data = [HeartRateData]()
        for _ in 0..<quantity {
            var heartRateData = HeartRateData()
            let now = Date()
            let bpmRange = 60...120
            var currentBPM = Int.random(in: bpmRange)
            for index in 0...6 {
                let time = Calendar.current.date(byAdding: .minute, value: -index, to: now)!
                let sample = HeartRateSample(id: UUID(), time: time, beatsPerMinute: currentBPM)
                heartRateData.samples.append(sample)
                let delta = Int.random(in: -10...10)
                currentBPM = max(bpmRange.lowerBound, min(bpmRange.upperBound, currentBPM + delta))
            }
            data.append(heartRateData)
        }
        return data
    }
}

struct HeartRateCellView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            HeartRateCellView(data: HeartRateData())
        }
    }
}
