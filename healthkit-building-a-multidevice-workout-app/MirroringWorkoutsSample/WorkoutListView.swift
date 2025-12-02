/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows a workout list.
*/

import os
import HealthKit
import SwiftUI

struct WorkoutListView: View {
    @Environment(\.dismiss) var dismiss
    /**
     workoutList either changes to a new array or doesn't change.
     HKWorkout is immutable, and this sample doesn't add or remove an array element.
     */
    @State private var workoutList = [HKWorkout]()
    @State private var selectedWorkout: HKWorkout?
    @State private var triggerAuthorization = false
    
    private let workoutManager = WorkoutManager.shared
    
    private var shortTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }

    var body: some View {
        listViewOrEmpty()
        .onAppear {
            triggerAuthorization.toggle()
        }
        .healthDataAccessRequest(store: workoutManager.healthStore,
                                 shareTypes: workoutManager.typesToShare,
                                 readTypes: workoutManager.typesToRead,
                                 trigger: triggerAuthorization) { result in
            switch result {
            case .success:
                Logger.shared.log("Successfully requested authorization.")
                Task {
                    workoutList = await workoutManager.fetchTodaysWorkouts(workoutType: .cycling)
                }
            case .failure(let error):
                Logger.shared.log("Failed to request authorization: \(error)")
            }
        }
    }
    
    @ViewBuilder
    private func listViewOrEmpty() -> some View {
        if workoutList.isEmpty {
            NavigationStack {
                VStack {
                    Text("Woop...").font(.title)
                    Text("You don't have any cycling yet today.").padding()
                }
                .toolbar {
                    toolbarItems()
                }
            }
        } else {
            NavigationSplitView {
                List(workoutList, id: \.self, selection: $selectedWorkout) { workout in
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        HStack {
                            Text(shortTimeFormatter.string(from: workout.startDate))
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(.footnote).weight(.semibold))
                        }

                    } else {
                        Text(shortTimeFormatter.string(from: workout.startDate))
                    }
                }
                .navigationTitle("Cycling Workouts")
                .toolbar {
                    toolbarItems()
                }
            } detail: {
                ChartView(workout: $selectedWorkout)
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarItems() -> some ToolbarContent {
        if UIDevice.current.userInterfaceIdiom == .phone {
            ToolbarItem(placement: .cancellationAction) {
                Button("Dismiss") {
                    dismiss()
                }
            }
        }
        ToolbarItem(placement: .automatic) {
            Button {
                Task {
                    workoutList = await workoutManager.fetchTodaysWorkouts(workoutType: .cycling)
                }
            } label: {
                Label("Refesh", systemImage: "arrow.clockwise")
            }
        }
    }
}
