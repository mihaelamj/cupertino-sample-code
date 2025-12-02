/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metrics.
*/

import SwiftUI
import HealthKit

struct MetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        TimelineView(MetricsTimelineSchedule(from: workoutManager.session?.startDate ?? Date(),
                                             isPaused: workoutManager.sessionState == .paused)) { context in
            VStack(alignment: .leading) {
                ElapsedTimeView(elapsedTime: elapsedTime(with: context.date), showSubseconds: context.cadence == .live)
                    .foregroundStyle(.yellow)
                Text(workoutManager.speed.formatted(.number.precision(.fractionLength(0))) + " mph")
                Text(workoutManager.cadence.formatted(.number.precision(.fractionLength(0))) + " rpm")
                Text(workoutManager.power.formatted(.number.precision(.fractionLength(0))) + " w")
                Text(workoutManager.water.formatted(.number.precision(.fractionLength(0))) + " oz")
            }
            .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
            .frame(maxWidth: .infinity, alignment: .leading)
            .ignoresSafeArea(edges: .bottom)
            .scenePadding()
            .padding([.top], 30)
        }
    }
    
    func elapsedTime(with contextDate: Date) -> TimeInterval {
        return workoutManager.builder?.elapsedTime(at: contextDate) ?? 0
    }
}
