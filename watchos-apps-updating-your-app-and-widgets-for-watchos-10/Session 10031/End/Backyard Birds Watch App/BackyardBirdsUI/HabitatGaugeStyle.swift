/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom gauge view that shows the availability of a resource.
*/

import SwiftUI

struct HabitatGaugeStyle: GaugeStyle {
    var habitatType: HabitatType
    var color: Color
    
    func minutesRemaining(_ level: Double) -> Int {
        let minutes = 30 + 30.0 * level
        return Int(minutes)
    }
    
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            Circle()
                .trim(from: 1 - CGFloat(configuration.value), to: 100.0)
                .rotation(.degrees(-90))
                .stroke(color, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .overlay {
                    ZStack {
                        Circle()
                            .stroke(.quaternary, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        VStack {
                            VStack {
                                Text("0:\(minutesRemaining(Double(configuration.value)))")
                                    .font(.title2)
                                Text("Remaining")
                                    .font(.caption2)
                                    .fontWeight(.regular)
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: habitatType.rawValue)
                                .foregroundStyle(.secondary)
                                .font(.title2)
                        }
                    }
                }
        }
    }
}
