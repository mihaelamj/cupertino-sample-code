/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows a button to start the watchOS app.
*/

import os
import SwiftUI
import HealthKitUI
import HealthKit

struct StartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var isFullScreenCoverActive = false
    @State private var didStartWorkout = false
    @State private var triggerAuthorization = false

    var body: some View {
        NavigationStack {
           VStack {
               Button {
                   if !workoutManager.sessionState.isActive {
                       startCyclingOnWatch()
                   }
                   didStartWorkout = true
               } label: {
                   let title = workoutManager.sessionState.isActive ? "View ongoing cycling" : "Start cycling on watch"
                   ButtonLabel(title: title, systemImage: "figure.outdoor.cycle")
                       .frame(width: 150, height: 150)
                       .fontWeight(.medium)
               }
               .clipShape(Circle())
               .overlay {
                   Circle().stroke(.white, lineWidth: 4)
               }
               .shadow(radius: 7)
               .buttonStyle(.bordered)
               .tint(.green)
               .foregroundColor(.black)
               .frame(width: 400, height: 400)
           }
           .onAppear() {
               triggerAuthorization.toggle()
               workoutManager.retrieveRemoteSession()
           }
           .healthDataAccessRequest(store: workoutManager.healthStore,
                                    shareTypes: workoutManager.typesToShare,
                                    readTypes: workoutManager.typesToRead,
                                    trigger: triggerAuthorization, completion: { result in
                switch result {
                case .success(let success):
                    print("\(success) for authorization")
                case .failure(let error):
                    print("\(error) for authorization")
                }
            })
           .navigationDestination(isPresented: $didStartWorkout) {
               MirroringWorkoutView()
           }
           .navigationBarTitle("Mirroring Workout")
           .navigationBarTitleDisplayMode(.inline)
           .toolbar {
               ToolbarItem(placement: .automatic) {
                   Button {
                       isFullScreenCoverActive = true
                   } label: {
                       Label("Workout list", systemImage: "list.bullet")
                   }
               }
           }
           .fullScreenCover(isPresented: $isFullScreenCoverActive) {
               WorkoutListView()
           }
        }
    }
        
    private func startCyclingOnWatch() {
        Task {
            do {
                try await workoutManager.startWatchWorkout(workoutType: .cycling)
            } catch {
                Logger.shared.log("Failed to start cycling on the paired watch.")
            }
        }
    }
}
