/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that controls the mirroring workout session and presents the metrics.
*/

import os
import SwiftUI
import HealthKit

struct MirroringWorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        NavigationStack {
            let fromDate = workoutManager.session?.startDate ?? Date()
            let schedule = MetricsTimelineSchedule(from: fromDate, isPaused: workoutManager.sessionState == .paused)
            TimelineView(schedule) { context in
                List {
                    Section {
                        metricsView()
                    } header: {
                        headerView(context: context)
                    } footer: {
                        footerView()
                    }
                }
            }
            .navigationBarTitle("Mirroring Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension MirroringWorkoutView {
    @ViewBuilder
    private func headerView(context: TimelineViewDefaultContext) -> some View {
        VStack {
            Spacer(minLength: 30)
            LabeledContent {
                ElapsedTimeView(elapsedTime: workoutTimeInterval(context.date), showSubseconds: context.cadence == .live)
                    .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
            } label: {
                Text("Elapsed")
            }
            .foregroundColor(.yellow)
            .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
            Spacer(minLength: 15)
        }
    }
    
    private func workoutTimeInterval(_ contextDate: Date) -> TimeInterval {
        var timeInterval = workoutManager.elapsedTimeInterval
        if workoutManager.sessionState == .running {
            if let referenceContextDate = workoutManager.contextDate {
                timeInterval += (contextDate.timeIntervalSinceReferenceDate - referenceContextDate.timeIntervalSinceReferenceDate)
            } else {
                workoutManager.contextDate = contextDate
            }
        } else {
            var date = contextDate
            date.addTimeInterval(workoutManager.elapsedTimeInterval)
            timeInterval = date.timeIntervalSinceReferenceDate - contextDate.timeIntervalSinceReferenceDate
            workoutManager.contextDate = nil
        }
        return timeInterval
    }
    
    @ViewBuilder
    private func metricsView() -> some View {
        Group {
            LabeledContent("Speed", value: workoutManager.speed, format: .number.precision(.fractionLength(0)))
            LabeledContent("Cadence", value: workoutManager.cadence, format: .number.precision(.fractionLength(0)))
            LabeledContent("Power", value: workoutManager.power, format: .number.precision(.fractionLength(0)))
            LabeledContent("Water", value: workoutManager.water, format: .number.precision(.fractionLength(0)))
            LabeledContent("Active Energy", value: workoutManager.activeEnergy, format: .number.precision(.fractionLength(0)))
            LabeledContent("Heart Rate", value: workoutManager.heartRate, format: .number.precision(.fractionLength(0)))
            LabeledContent("Distance", value: workoutManager.distance, format: .number.precision(.fractionLength(0)))
        }
        .font(.system(.title2, design: .rounded).monospacedDigit().lowercaseSmallCaps())
    }
    
    @ViewBuilder
    private func footerView() -> some View {
        VStack {
            Spacer(minLength: 40)
            HStack {
                Button {
                    if let session = workoutManager.session {
                        workoutManager.sessionState == .running ? session.pause() : session.resume()
                    }
                } label: {
                    let title = workoutManager.sessionState == .running ? "Pause" : "Resume"
                    let systemImage = workoutManager.sessionState == .running ? "pause" : "play"
                    ButtonLabel(title: title, systemImage: systemImage)
                }
                .disabled(!workoutManager.sessionState.isActive)

                Button {
                    workoutManager.session?.stopActivity(with: .now )
                } label: {
                    ButtonLabel(title: "End", systemImage: "xmark")
                }
                .tint(.green)
                .disabled(!workoutManager.sessionState.isActive)

                Spacer()
                
                Button {
                    recordWaterIntake()
                } label: {
                    ButtonLabel(title: "Water", systemImage: "drop.fill")
                }
                .tint(.blue)
                .disabled(!workoutManager.sessionState.isActive)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func recordWaterIntake() {
        Task {
            let waterQuantity = HKQuantity(unit: HKUnit.fluidOunceUS(), doubleValue: 1.0)
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: waterQuantity, requiringSecureCoding: true) {
                await workoutManager.sendData(data)
                workoutManager.water += 1
            }
        }
    }
}
