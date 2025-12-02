/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A gauge view that shows the availability of a resource.
*/

import SwiftUI

struct HabitatGauge: View {
    let title: String
    private let gradient = Gradient(colors: [.red, .yellow, .green])
    
    @Binding var percent: Int
    
    var body: some View {
        VStack {
            Text(title)
            Gauge(value: Double(percent) / 100) {
                Text(title)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
            } currentValueLabel: {
                Text("\(percent)")
            }
            .gaugeStyle(LinearGaugeStyle(tint: gradient))
        }
    }
}

struct HabitatGauge_Previews: PreviewProvider {
    static var previews: some View {
        HabitatGauge(title: "Food", percent: .constant(50))
    }
}
