/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view of a backyard.
*/

import SwiftUI

struct BackyardView: View {
    var backyard: Backyard
    
    @State var waterLevel = 30
    @State var foodLevel = 60
    
    @State var isShowingRefillView = false
    
    func backgroundColor(_ level: Int, for type: HabitatType) -> Color {
        let color: Color = type == .food ? .green : .blue
        return level < 40 ? .red : color
    }
    
    var waterColor: Color {
        backgroundColor(waterLevel, for: .water)
    }
    var foodColor: Color {
        backgroundColor(foodLevel, for: .food)
    }
    
    var body: some View {
        TabView {
            TodayView()
                .navigationTitle("Today")
                .containerBackground(Color.accentColor.gradient, for: .tabView)
            HabitatGaugeView(level: $waterLevel, habitatType: .water, tintColor: waterColor)
                .navigationTitle("Water")
                .containerBackground(waterColor.gradient, for: .tabView)
            HabitatGaugeView(level: $foodLevel, habitatType: .food, tintColor: foodColor)
                .navigationTitle("Food")
                .containerBackground(foodColor.gradient, for: .tabView)
            List {
                VisitorView()
                    .navigationTitle("Visitors")
                    .containerBackground(Color.accentColor.gradient, for: .tabView)
            }
        }
        .tabViewStyle(.verticalPage)
        .environmentObject(backyard)
        .navigationTitle(backyard.displayName)
    }
}

struct BackyardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BackyardView(backyard: .preview)
        }
    }
}
