/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout summary.
*/

import HealthKit
import SwiftUI

struct SummaryView: View {
    @Binding var workout: HKWorkout?

    var body: some View {
        if let workout = workout {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                GridItemView(title: "Total Time", value: workout.totalTime)
                    .foregroundStyle(.yellow)
                
                GridItemView(title: "Total Distance", value: workout.totalCyclingDistance)
                    .foregroundStyle(.orange)
                
                GridItemView(title: "Total Energy", value: workout.totalEnergy)
                    .foregroundStyle(.pink)
                
                GridItemView(title: "Average Speed", value: workout.averageCyclingSpeed)
                    .foregroundStyle(.green)
                
                GridItemView(title: "Average Power", value: workout.averageCyclingPower)
                    .foregroundStyle(.pink)
                
                GridItemView(title: "Average Cadence", value: workout.averageCyclingCadence)
                    .foregroundStyle(.black)
            }
        }
    }
}

private struct GridItemView: View {
    var title: String
    var value: String

    var body: some View {
        VStack {
            Text(title)
                .foregroundStyle(.foreground)
            Text(value)
                .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
        }
    }
}
