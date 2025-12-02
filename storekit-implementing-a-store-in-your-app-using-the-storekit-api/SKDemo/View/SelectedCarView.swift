/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The selected Car.
*/

import SwiftUI

struct SelectedCarView: View {
    @Environment(\.selectedCar) private var selectedCar

    var body: some View {
        Image(systemName: selectedCar.decorativeIconName)
            .symbolVariant(.fill)
            .font(.system(size: 100))
            .padding()

        SelectedCarMetricsView()
    }
}

private struct SelectedCarMetricsView: View {
    @Environment(\.selectedCar) private var selectedCar

    private var carMetrics: [Car.Metric] {
        Array(selectedCar.metrics.sorted(by: { $0.name < $1.name }))
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                ForEach(carMetrics, id: \.self) { carMetric in
                    VStack(alignment: .leading, spacing: .zero) {
                        Text(verbatim: carMetric.name)
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Capsule(style: .circular)
                            .fill(.tint)
                            .frame(height: 28)
                            .containerRelativeFrame(.horizontal) { length, _ in
                                length * CGFloat(carMetric.value) / 100
                            }
                            .overlay(alignment: .leading) {
                                Text(verbatim: carMetric.value.formatted())
                                    .foregroundStyle(.white)
                                    .font(.callout)
                                    .padding(.horizontal, 5)
                            }
                    }
                    .fontWeight(.semibold)
                }
            }
            Spacer(minLength: .zero)
        }
    }
}
