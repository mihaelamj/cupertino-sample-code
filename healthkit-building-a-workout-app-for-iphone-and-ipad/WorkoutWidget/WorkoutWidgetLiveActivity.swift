/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A widget for the workout widget.
*/

import ActivityKit
import WidgetKit
import SwiftUI
import Foundation

struct WorkoutWidgetLiveActivity: Widget {
    @Environment(\.redactionReasons) var redactionReasons
    var body: some WidgetConfiguration {
        
        ActivityConfiguration(for: WorkoutWidgetAttributes.self) { context in
            LiveActivityView(context: context)
            .padding()
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    LiveActivityView(context: context)
                }
            } compactLeading: {
                Image(systemName: context.attributes.symbol)
                    .foregroundColor(.accent)
            } compactTrailing: {
                ElapsedTimeView(elapsedTime: context.state.metrics.elapsedTime)
            } minimal: {
                Image(systemName: context.attributes.symbol)
                    .foregroundColor(.accent)
            }
            .keylineTint(Color.red)
        }
    }
}

extension WorkoutWidgetAttributes {
    fileprivate static var preview: WorkoutWidgetAttributes {
        WorkoutWidgetAttributes(symbol: "figure.run")
    }
}

extension WorkoutWidgetAttributes.ContentState {
    fileprivate static var live: WorkoutWidgetAttributes.ContentState {
        let metrics = MetricsModel(elapsedTime: 120,
                                   heartRate: 72,
                                   activeEnergy: 65,
                                   distance: 123,
                                   speed: 4.5,
                                   supportsDistance: true,
                                   supportsSpeed: true)
        return WorkoutWidgetAttributes.ContentState(state: 99, metrics: metrics)
     }
     
    fileprivate static var stale: WorkoutWidgetAttributes.ContentState {
        let metrics = MetricsModel(elapsedTime: 120)
        return WorkoutWidgetAttributes.ContentState(state: -99, metrics: metrics)
    }
    
    fileprivate static var someMetrics: WorkoutWidgetAttributes.ContentState {
        let metrics = MetricsModel(elapsedTime: 120,
                                   heartRate: nil,
                                   activeEnergy: 65,
                                   distance: nil,
                                   speed: nil,
                                   supportsDistance: false,
                                   supportsSpeed: false)
        return WorkoutWidgetAttributes.ContentState(state: 99, metrics: metrics)
     }
    
}

#Preview("Notification", as: .content, using: WorkoutWidgetAttributes.preview) {
   WorkoutWidgetLiveActivity()
} contentStates: {
    WorkoutWidgetAttributes.ContentState.live
    WorkoutWidgetAttributes.ContentState.stale
    WorkoutWidgetAttributes.ContentState.someMetrics
}
