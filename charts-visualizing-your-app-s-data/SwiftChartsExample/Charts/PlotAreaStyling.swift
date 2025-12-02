/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Plot area styling definitions.
*/

import Charts
import SwiftUI

struct ChartWithBackgroundChart: View {
    let data: [(name: String, sales: Int)]

    var body: some View {
        Chart(data, id: \.name) { element in
            BarMark(
                x: .value("Sales", element.sales),
                y: .value("Name", element.name)
            )
            .foregroundStyle(.pink)
        }
        .chartPlotStyle {
            $0.background(.pink.opacity(0.2))
                .border(Color.pink, width: 1)
        }
    }
}

struct ChartWithBackground: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Most Sold Style")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Text(TopStyleData.last30Days.first!.name)
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                ChartWithBackgroundChart(data: TopStyleData.last30Days)
                    .frame(height: 300)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        #if !os(macOS)
        .navigationBarTitle("Plot Area Styling", displayMode: .inline)
        #endif
    }
}

#Preview {
    ChartWithBackground()
}
