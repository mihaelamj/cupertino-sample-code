/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
User interface configuration values.
*/

import Foundation
import SwiftData

/// User interface configuration values.
@Observable
class ViewModel {
    /// The parameter to order quakes by in the list view.
    var sortParameter: SortParameter = .time

    /// The sort direction for quakes in the list view.
    var sortOrder: SortOrder = .reverse

    /// A location name to use when filtering quakes.
    var searchText: String = ""

    /// A date to use when filtering quakes.
    ///
    /// Both the list and map views display only the quakes that occur between
    /// the start and end of the day in the current time zone that contain
    /// the point in time represented by this date.
    var searchDate: Date = .now

    /// The range of dates that the date picker offers for filtering quakes.
    ///
    /// The app recalculates this range when the list of quakes changes, like
    /// after loading new quakes or deleting existing ones, to
    /// include the full range of dates over all the stored quakes.
    var searchDateRange: ClosedRange<Date> = .distantPast ... .distantFuture

    /// The total number of quakes in the store.
    var totalQuakes: Int = 0

    /// Updates the search date and search date range based on the current
    /// set of stored quakes.
    func update(modelContext: ModelContext) {
        searchDateRange = Quake.dateRange(modelContext: modelContext)
        searchDate = min(searchDateRange.upperBound, .now)
        totalQuakes = Quake.totalQuakes(modelContext: modelContext)
    }
}
