/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for date interval formatter.
*/

import SwiftUI

@MainActor
@Observable class DateIntervalFormatterModel {
    var startDate: Date
    var endDate: Date
    
    var formatter: DateIntervalFormatter
    var dateStyle: DateIntervalFormatter.Style { didSet { updateFormatter() } }
    var timeStyle: DateIntervalFormatter.Style { didSet { updateFormatter() } }
    
    var localizedDateInterval: String {
        string(from: startDate, to: endDate)
    }
    
    init() {
        /*
            ISO 8601 is a standard that defines date or time formats in a locale-independent manner
            you can use for technical interchange. It is useful for initializing a specific date or time.
        */
        self.startDate = ISO8601DateFormatter().date(from: "2025-06-09T09:41:00-07:00")!
        self.endDate = ISO8601DateFormatter().date(from: "2025-06-13T18:00:00-07:00")!
        self.formatter = DateIntervalFormatter()
        self.dateStyle = .medium
        self.timeStyle = .none
        self.updateFormatter()
    }
    
    private func string(from fromDate: Date, to toDate: Date) -> String {
        formatter.string(from: fromDate, to: toDate)
    }

    private func updateFormatter() {
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle
    }
}
