/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods that manage which widgets and Live Activities are available.
*/

import WidgetKit
import SwiftUI

@main
struct OrderStatusBundle: WidgetBundle {
    var body: some Widget {
        OrderStatus()
        OrderStatusLiveActivity()
    }
}
