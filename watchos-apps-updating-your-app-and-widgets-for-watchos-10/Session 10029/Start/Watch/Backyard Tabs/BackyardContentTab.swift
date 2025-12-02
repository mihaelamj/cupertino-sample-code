/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The backyard content tab.
*/

import SwiftUI
import BackyardBirdsData
import WidgetKit

struct BackyardContentTab: View {
    var backyard: Backyard
    
    var body: some View {
        VStack {
            Spacer()
            
            Label("Food is running low", systemImage: "fork.knife")
            Label("Water is OK", systemImage: "cup.and.saucer.fill")

            Button("Refill") {
                withAnimation {
                    backyard.waterRefillDate = .now
                    backyard.foodRefillDate = .now
                }
            }
            
            Spacer()
        }
        .containerBackground(.green.gradient, for: .tabView)
        .navigationTitle("Amenities")
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Gauge(value: 0.5) {
                    Label("Water", systemImage: "cup.and.saucer.fill")
                } currentValueLabel: {
                    Text(Duration.seconds(60 * (59 + 4 * 60)), format: timeFormatter)
                }
                .tint(Gradient(colors: [.blue, .green]))
                .gaugeStyle(.accessoryCircularCapacity)
                
                Gauge(value: 0.25) {
                    Label("Food", systemImage: "fork.knife")
                } currentValueLabel: {
                    Text(Duration.seconds(60 * (59 + 6 * 60)), format: timeFormatter)
                }
                .tint(Gradient(colors: [.yellow, .orange]))
                .gaugeStyle(.accessoryCircularCapacity)
            }
        }
    }
    
    let timeFormatter: Duration.TimeFormatStyle = Duration.TimeFormatStyle(pattern: .hourMinute)
}

#Preview {
    ModelPreview { backyard in
        TabView {
            BackyardContentTab(backyard: backyard)
        }
        .tabViewStyle(.carousel)
    }
}
