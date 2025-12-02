/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Styles Details definitions.
*/

import Charts
import SwiftUI

struct StylesDetailsChart: View {
    let data: [(name: String, sales: Int)]
    let mostSold: (name: String, sales: Int)
    
    let cumulativeSalesRangesForStyles: [(name: String, range: Range<Double>)]
    
    @State var selectedSales: Double? = nil
    
    init(data: [(name: String, sales: Int)], mostSold: (name: String, sales: Int)) {
        self.data = data
        self.mostSold = mostSold
        
        var cumulative = 0.0
        self.cumulativeSalesRangesForStyles = data.map {
            let newCumulative = cumulative + Double($0.sales)
            let result = (name: $0.name, range: cumulative ..< newCumulative)
            cumulative = newCumulative
            return result
        }
    }
    
    var selectedStyle: (name: String, sales: Int)? {
        if let selectedSales,
           let selectedIndex = cumulativeSalesRangesForStyles
            .firstIndex(where: { $0.range.contains(selectedSales) }) {
            return data[selectedIndex]
        }
        
        return nil
    }

    var body: some View {
        Chart(data, id: \.name) { element in
            SectorMark(
                angle: .value("Sales", element.sales),
                innerRadius: .ratio(0.618),
                angularInset: 1.5
            )
            .cornerRadius(5.0)
            .foregroundStyle(by: .value("Name", element.name))
            .opacity(element.name == (selectedStyle?.name ?? mostSold.name) ? 1 : 0.3)
        }
        .chartLegend(alignment: .center, spacing: 18)
        .chartAngleSelection(value: $selectedSales)
        .scaledToFit()
        #if os(macOS)
        .transaction {
            $0.animation = nil // Do not animate on MacOS.
        }
        #endif

        .chartBackground { chartProxy in
            GeometryReader { geometry in
                let frame = geometry[chartProxy.plotFrame!]
                VStack {
                    Text("Most Sold Style")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .opacity(selectedStyle == nil || selectedStyle?.name == mostSold.name ? 1 : 0)
                    Text(selectedStyle?.name ?? mostSold.name)
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    Text((selectedStyle?.sales.formatted() ?? mostSold.sales.formatted()) + " sold")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }
}

struct StylesDetails: View {
    @State private var timeRange: TimeRange = .last30Days

    var data: [(name: String, sales: Int)] {
        switch timeRange {
        case .last12Months:
            return TopStyleData.last12Months
        case .last30Days:
            return TopStyleData.last12Months.map { (name, _) in
                // Keep the annual order for consistent sector ordering.
                return (
                    name: name,
                    sales: TopStyleData.last30Days.first(where: { $0.name == name })?.sales ?? 0
                )
            }
        }
    }

    var body: some View {
        List {
            VStack(alignment: .leading) {
                TimeRangePicker(value: $timeRange)
                    .padding(.bottom)
                    .transaction {
                        $0.animation = nil // Do not animate the picker.
                    }

                StylesDetailsChart(
                    data: data,
                    mostSold: data.first ?? (name: "Unknown", sales: 0)
                )
            }
            .listRowSeparator(.hidden)

            Section("Options") {
                TransactionsLink()
            }
        }
        .listStyle(.plain)
        #if !os(macOS)
        .navigationBarTitle("Style", displayMode: .inline)
        #endif
        .navigationDestination(for: [Transaction].self) { transactions in
            TransactionsView(transactions: transactions)
        }
    }
}

#Preview {
    StylesDetails()
}
