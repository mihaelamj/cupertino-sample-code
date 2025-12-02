/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout summary information.
*/

import SwiftUI
import HealthKit

struct SummaryView: View {
    @Environment(WorkoutManager.self) var workoutManager
    @Environment(\.dismiss) var dismiss
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    var body: some View {
        if workoutManager.workout == nil {
            VStack {
                Spacer()
                ProgressView("Saving workout")
                    .navigationBarHidden(true)
                    .tint(.accent)
                    .foregroundColor(.accent)
                Spacer()
            }
            .transition(.opacity)
        } else {
            List {
                HStack {
                    Image(systemName: "\(workoutManager.workoutConfiguration?.symbol ?? "figure.walk").circle.fill")
                        .font(.title)
                        .foregroundColor(.accent)
                    Text("\(workoutManager.workoutConfiguration?.name ?? "Outdoor Walk")")
                }
                
                SummaryMetricView(
                    title: "Total Time",
                    value: durationFormatter
                        .string(from: workoutManager.workout?.duration ?? 0.0) ?? ""
                ).accentColor(Color.yellow)
                
                if workoutManager.workout?.workoutConfiguration.supportsDistance ?? false {
                    SummaryMetricView(
                        title: "Total Distance",
                        value: Measurement(
                            value: workoutManager.workout?.totalDistance?
                                .doubleValue(for: .meter()) ?? 0,
                            unit: UnitLength.meters
                        ).formatted(
                            .measurement(
                                width: .abbreviated,
                                usage: .road
                            )
                        )
                    ).accentColor(Color.blue)
                }
                
                SummaryMetricView(
                    title: "Total Energy",
                    value: Measurement(
                        value: workoutManager.workout?.statistics(for: .quantityType(forIdentifier: .activeEnergyBurned)!)?
                            .sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0,
                        unit: UnitEnergy.kilocalories
                    ).formatted(
                        .measurement(
                            width: .abbreviated,
                            usage: .workout
                        )
                    )
                ).accentColor(Color.pink)
            }
            .listStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        withAnimation {
                            workoutManager.resetWorkout()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .imageScale(.large)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct SummaryMetricView: View {
    var title: String
    var value: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
            Text(value)
                .font(.system(.title, design: .rounded)
                    .lowercaseSmallCaps()
                )
                .foregroundColor(.accentColor)
        }
    }
}
