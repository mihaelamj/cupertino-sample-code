/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A widget bundle that shows the Live Activity.
*/

import WidgetKit
import SwiftUI

@main
struct WorkoutWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorkoutWidgetLiveActivity()
    }
}
