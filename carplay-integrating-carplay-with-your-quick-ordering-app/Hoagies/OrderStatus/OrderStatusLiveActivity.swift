/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods that manage the Live Activity view state.
*/

import ActivityKit
import WidgetKit
import SwiftUI

struct OrderStatusLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OrderStatusAttributes.self) { context in
            // The Lock Screen or banner UI goes here.
            OrderStatusView(state: context.state)
            .padding()
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Place the expanded UI here. Compose the expanded UI through
                // various regions, such as `.leading`, `.trailing`, `.center`, or `.bottom`.
                DynamicIslandExpandedRegion(.leading) {
                    OrderStatusIcon(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(Date(timeIntervalSinceReferenceDate: context.attributes.hoagieOrder.date), style: .relative)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("\(context.attributes.hoagieOrder.order.joined(separator: "\n"))")
                }
            } compactLeading: {
                OrderStatusIcon(state: context.state)
            } compactTrailing: {
                ProgressView(
                    value: context.attributes.hoagieOrder.date,
                    total: context.attributes.hoagieOrder.date.advanced(by: TestHoagieData.tenMinutes))
                .progressViewStyle(.circular)
            } minimal: {
                OrderStatusIcon(state: context.state)
            }
            // In an iOS app running on a Mac, the widgets launch Safari if there isn't an app to launch.
            .widgetURL(URL(string: "https://developer.apple.com/documentation/activitykit"))
            .keylineTint(Color.red)
        }
    }
}
