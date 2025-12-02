/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Styles Overview definitions.
*/

import Charts
import SwiftUI

struct StylesOverviewChart: View {
    var body: some View {
        Chart(TopStyleData.last30Days, id: \.name) { element in
            SectorMark(
                angle: .value("Sales", element.sales),
                innerRadius: .ratio(0.618),
                angularInset: 1
            )
            .cornerRadius(3.0)
            .foregroundStyle(by: .value("Name", element.name))
            .opacity(element.name == TopStyleData.last30Days.first!.name ? 1 : 0.3)
        }
        .chartLegend(.hidden)
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
    }
}

struct StylesOverview: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Most Sold Style")
                .foregroundStyle(.secondary)
            Text(TopStyleData.last30Days.first!.name)
                .font(.title2.bold())
            StylesOverviewChart()
                .frame(height: 100)
        }
    }
}

#Preview {
    StylesOverview()
        .padding()
}
