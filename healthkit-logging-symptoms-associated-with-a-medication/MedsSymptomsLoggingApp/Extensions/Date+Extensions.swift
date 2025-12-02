/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A file containing extensions for working with dates.
*/

import Foundation

// MARK: - DateFormatter

extension DateFormatter {
    static let chartDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .short
        return dateFormatter
    }()
}

// MARK: - DateInterval

extension DateInterval {
    static var weeklyInterval: DateInterval {
        let end = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .day, value: -7, to: end)!
        return DateInterval(start: start, end: end)
    }
}
