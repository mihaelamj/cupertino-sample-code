/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metric and controls as a single view.
*/

import SwiftUI

struct SessionView: View {
    @Environment(WorkoutManager.self) var workoutManager

    var body: some View {
        VStack {
            Image(systemName: "\(workoutManager.workoutConfiguration?.symbol ?? "figure.walk").circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.accent)
            MetricsView()
                .padding(.vertical)
            ControlsView()
        }
    }
}

#Preview {
    NavigationView {
        SessionView()
            .environment(WorkoutManager())
    }
}
