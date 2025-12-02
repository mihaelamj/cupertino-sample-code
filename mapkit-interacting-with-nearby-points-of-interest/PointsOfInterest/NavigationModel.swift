/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object with state information for `NavigationSplitView`.
*/

import Foundation
import Observation
import SwiftUI

@Observable class NavigationModel {
    /// Show the map by default on iPhone.
    var preferredCompactColumn = NavigationSplitViewColumn.detail
    
    /// The currently visible column of `NavigationSplitView`.
    var columnVisibility = NavigationSplitViewVisibility.doubleColumn
}
