/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view displaying the details of an individual's ongoing activity.
*/

import SwiftUI

struct ActiveActivityInfoView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(ActivityTracker.self) private var activityTracker
    @Environment(TrailDataManager.self) private var trailManager
    
    var body: some View {
        #if os(watchOS)
        ScrollView {
            viewContents
        }
        #else
        viewContents
        #endif
    }
    
    private var viewContents: some View {
        VStack(alignment: .center) {
            if let activity = activityTracker.activityInProgress,
               let trail = trailManager.trail(with: activity.trail) {
                Text("\(activity.style.localizedStringResource) on \(trail.name)")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            if let nextManeuver = activityTracker.nextManeuver {
                Text(nextManeuver)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Button("End Activity") {
                Task { @MainActor in
                    activityTracker.endActivity()
                    navigationModel.displayInProgressActivityInfo = false
                }
            }
            .buttonStyle(.bordered)
        }
    }
}
