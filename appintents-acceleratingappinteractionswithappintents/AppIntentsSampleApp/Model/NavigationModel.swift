/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages selection in the app's UI.
*/

import Foundation
import Observation
import SwiftUI

/// An observable object that manages the selection events for `NavigationSplitView`.
@MainActor
@Observable class NavigationModel {

    /// The selected item in `SidebarColumn`.
    var selectedCollection: TrailCollection?
    
    /// The selected item in the `NavigationSplitView` content view.
    var selectedTrail: Trail?
    
    /// The column visibility in `NavigationSplitView`.
    var columnVisibility: NavigationSplitViewVisibility
    
    /// The column visibility when `NavigationSplitView` collapses in a compact enviroment.
    var preferredCompactColumn: NavigationSplitViewColumn
    
    /// The visibility of a sheet when an activity is active.
    var displayInProgressActivityInfo = false
    
    init(selectedCollection: TrailCollection? = nil,
         columnVisibility: NavigationSplitViewVisibility = .all,
         preferredCompactColumn: NavigationSplitViewColumn = .content) {
        self.selectedCollection = selectedCollection
        self.columnVisibility = columnVisibility
        self.preferredCompactColumn = preferredCompactColumn
    }
}
