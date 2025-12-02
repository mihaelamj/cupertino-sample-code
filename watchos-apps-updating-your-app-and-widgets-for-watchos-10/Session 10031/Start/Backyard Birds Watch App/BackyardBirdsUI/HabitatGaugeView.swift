/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view with a gauge that implements the custom HabitatGaugeStyle.
*/

import SwiftUI

struct HabitatGaugeView: View {
    @Binding var level: Int
    var habitatType: HabitatType
    var tintColor: Color
 
    var body: some View {
        Gauge(value: Double(level), in: 0...100) {
            Text("Habitat gauge")
        }
        .gaugeStyle(HabitatGaugeStyle(habitatType: habitatType, color: tintColor))
    }
}

struct HabitatGaugeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TabView {
                HabitatGaugeView(level: .constant(80), habitatType: .water, tintColor: .blue)
            }
        }
    }
}
