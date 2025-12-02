/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metrics.
*/

import SwiftUI
import HealthKit

struct MetricsView: View {
    @Environment(WorkoutManager.self) var workoutManager
    var body: some View {
        TimelineView(
            MetricsTimelineSchedule(
                from: workoutManager.builder?.startDate ?? Date(), isPaused: workoutManager.session?.state == .paused
            )
        ) { context in
            ScrollView {
                VStack(alignment: .custom) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.yellow)
                            .font(.system(size: 60))
                            .rotationEffect(.degrees(45))
                            .padding(.trailing)
                        ElapsedTimeView(
                            elapsedTime: workoutManager.builder?.elapsedTime ?? 0)
                            .alignmentGuide(.custom) { $0[.leading] }
                    }
                    
                    if workoutManager.metrics.supportsDistance {
                        HStack {
                            Image(systemName: "lines.measurement.horizontal")
                                .foregroundColor(.green)
                                .font(.system(size: 60))
                                .padding(.trailing)
                            Text(workoutManager.metrics.getDistance())
                            .alignmentGuide(.custom) { $0[.leading] }
                        }
                        .padding()
                    }
                    
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 60))
                            .padding(.trailing)
                        Text(workoutManager.metrics.getHeartRate()
                            + " bpm")
                            .alignmentGuide(.custom) { $0[.leading] }
                    }
                    
                    .padding()
                    
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.purple)
                            .font(.system(size: 60))
                            .padding(.trailing)
                        Text(workoutManager.metrics.getActiveEnergy())
                            .alignmentGuide(.custom) { $0[.leading] }
                        Text("Active\nEnergy")
                            .font(.system(.body, design: .rounded).smallCaps())
                    }
                    
                    .padding()
                
                    if workoutManager.metrics.supportsSpeed {
                        HStack {
                            Image(systemName: "hare.fill")
                                .foregroundColor(.teal)
                                .font(.system(size: 60))
                            Text(workoutManager.metrics.getSpeed())
                            .alignmentGuide(.custom) { $0[.leading] }
                        }
                    }
                }
                .font(
                    .system(size: CGFloat(50), design: .rounded)
                    .monospacedDigit()
                    .lowercaseSmallCaps()
                )
                .scenePadding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct CustomAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        return context[.leading]
    }
}

extension HorizontalAlignment {
    static let custom: HorizontalAlignment = HorizontalAlignment(CustomAlignment.self)
}

#Preview {
    let workoutManager = WorkoutManager()
    let configuration = HKWorkoutConfiguration()
    configuration.activityType = .running
    configuration.locationType = .outdoor
    workoutManager.selectedWorkout = configuration
    let metrics = MetricsModel(elapsedTime: 600,
                               heartRate: 72,
                               activeEnergy: 143,
                               distance: 5000,
                               speed: 1.4,
                               supportsDistance: true,
                               supportsSpeed: true)
    workoutManager.metrics = metrics
    
    return MetricsView()
        .environment(workoutManager)
}

private struct MetricsTimelineSchedule: TimelineSchedule {
    let startDate: Date
    let isPaused: Bool

    init(from startDate: Date, isPaused: Bool) {
        self.startDate = startDate
        self.isPaused = isPaused
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        let newMode = (mode == .lowFrequency ? 1.0 : 1.0 / 30.0)
        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate, by: newMode).entries(from: startDate, mode: mode)

        return AnyIterator<Date> {
            return isPaused ? nil : baseSchedule.next()
        }
    }
}
