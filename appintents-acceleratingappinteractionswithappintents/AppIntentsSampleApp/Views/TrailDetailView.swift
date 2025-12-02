/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays information about a trail, plus an individual's activity history for that trail.
*/

import SwiftUI

struct TrailDetailView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(TrailDataManager.self) private var trailManager
    @Environment(ActivityTracker.self) private var activityTracker
    
    var trail: Trail
    
    /// - Returns: The activity history for this trail, sorted with the most recent entry at the top.
    private var activityHistory: [Activity] {
        activityTracker.activityHistory(on: trail.id)
            .sorted(using: KeyPathComparator(\Activity.start, order: .reverse))
    }
    
    private let distanceFormatter = MeasurementFormatter()
    
    var body: some View {
        List {
        #if !os(watchOS)
            TrailInfoView(trail: trail)
        #endif
            detailSection
            activityHistorySection
        }
        .navigationTitle(trail.name)
        
    #if os(iOS) || os(visionOS)
        .listStyle(.grouped)
        .navigationBarTitleDisplayMode(.inline)
    #endif
    }
    
    private var detailSection: some View {
        Section("Details") {
        #if os(watchOS)
            DetailItem(label: "Trail", value: trail.name)
            DetailItem(label: "Location", value: trail.regionDescription)
        #endif
            DetailItem(label: "Current Conditions", value: trail.currentConditions)
            DetailItem(label: "Activities", value: trail.activities.formattedDisplayValue)
            DetailItem(label: "Trail Length", value: distanceFormatter.string(from: trail.trailLength))
            DetailItem(label: "Distance To Trail",
                       value: distanceFormatter.string(from: trail.distanceToTrail))
            DetailItem(label: "Coordinate", value: trail.coordinate.formattedDisplayValue)
        }
    }
    
    private var activityHistorySection: some View {
        Section {
            let buttonTitle = activityTracker.activityInProgress == nil ? "Start Activity" : "End Activity"
            if activityTracker.activityInProgress == nil || activityTracker.activityInProgress?.trail == trail.id {
                Button(buttonTitle) {
                    Task { @MainActor in
                        guard try await activityTracker.requestActivityTrackingAuthorization() else {
                            return
                        }
                        
                        if activityTracker.activityInProgress == nil {
                            try await activityTracker.startNewActivity(trail.activities.first!, on: trail)
                            navigationModel.displayInProgressActivityInfo = true
                        } else {
                            activityTracker.endActivity()
                            navigationModel.displayInProgressActivityInfo = false
                        }
                    }
                }
            }
            
            let activities = activityHistory
            if activities.isEmpty {
                Text("No Activity History")
            } else {
                ForEach(activityHistory) { activity in
                    ActivityHistoryItem(activity: activity)
                }
            }
        } header: {
            Text("Activity History")
        } footer: {
            Text("Record activites through Siri, Spotlight, the Shortcuts app, or the Action button on Apple Watch Ultra.")
        }
    }
}
