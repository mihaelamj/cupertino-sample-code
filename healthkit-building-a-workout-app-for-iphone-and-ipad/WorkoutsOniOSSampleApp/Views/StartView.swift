/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows a list of various workouts to start.
*/

import SwiftUI
import HealthKit

struct StartView: View {
    @Environment(WorkoutManager.self) var workoutManager

    var body: some View {
        VStack {
            @Bindable var workoutManager = workoutManager
            List(WorkoutTypes.workoutConfigurations, id: \.self, selection: $workoutManager.selectedWorkout) { workoutConfiguration in
                Label {
                    Text(workoutConfiguration.name)
                        .fontWeight(.semibold)
                        .padding(.leading)
                } icon: {
                    Image(systemName: workoutConfiguration.symbol)
                        .font(.title)
                        .foregroundColor(.accent)
                        .padding(.leading)
                        .padding(.top, 5.0)
                        .padding(.bottom, 5.0)
                }
                .frame(minHeight: 50.0)
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 15.0, style: .continuous)
                        .fill(Color("AccentColor").opacity(0.16))
                )
            }
            .listRowSpacing(8)
            .listRowSeparator(.hidden)
            .navigationBarTitle("Workouts")
            .onAppear {
                workoutManager.requestAuthorization()
            }
        }
    }
}

#Preview {
    NavigationStack {
        StartView()
            .environment(WorkoutManager())
    }
}
