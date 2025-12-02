/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows the resources of a backyard.
*/

import SwiftUI

struct HabitatView: View {
    @Binding var isShowingRefillView: Bool
    
    @Binding var waterLevel: Int
    @Binding var foodLevel: Int
    
    init(_ isShowingRefillView: Binding<Bool>, _ waterLevel: Binding<Int>, _ foodLevel: Binding<Int>) {
        self._isShowingRefillView = isShowingRefillView
        self._waterLevel = waterLevel
        self._foodLevel = foodLevel
    }
    
    var body: some View {
        VStack {
            Spacer()
            Label("**Food** 0:\(minutesRemaining(foodLevel))", systemImage: "fork.knife")
            Label("**Water** 0:\(minutesRemaining(waterLevel))", systemImage: "cup.and.saucer.fill")
            Spacer()
            HabitatGauge(title: "Food", percent: $foodLevel)
            Spacer()
            HabitatGauge(title: "Water", percent: $waterLevel)
            Spacer()
        }
        .listRowBackground(Color.clear)
        .font(.caption)
        .padding(.top)
        .sheet(isPresented: $isShowingRefillView) {
            BackyardRefillOptions(waterValue: $waterLevel, foodValue: $foodLevel)
        }
    }
    
    func minutesRemaining(_ level: Int) -> Int {
        let minutes = 30 + 30.0 * (Double(level) / 100.0)
        return Int(minutes)
    }
}

struct HabitatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            List {
                HabitatView(.constant(false), .constant(30), .constant(20))
            }
        }
    }
}
