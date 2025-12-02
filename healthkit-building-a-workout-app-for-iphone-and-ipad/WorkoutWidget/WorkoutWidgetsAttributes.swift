/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure that wraps the data you use for the widget.
*/

import ActivityKit
import Foundation

struct WorkoutWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        
        let state: Int
        let metrics: MetricsModel
    }

    // Fixed nonchanging properties about your activity go here.
    var symbol: String
}
