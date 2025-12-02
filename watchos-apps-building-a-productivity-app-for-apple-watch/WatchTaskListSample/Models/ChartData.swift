/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Aggregate data to display in a chart.
*/

import Foundation

/// Aggregate data for charting productivity.
struct ChartData {
    struct DataElement: Identifiable {
        var id: Date { return date }
        let date: Date
        let itemsComplete: Double
    }
    
    /// Create aggregate chart data from list items.
    /// - Parameter items: An array of list items to aggregate for charting.
    /// - Returns: The chart data source.
    static func createData(_ items: [ListItem]) -> [DataElement] {
        return Dictionary(grouping: items, by: \.completionDate)
            .compactMap {
                guard let date = $0 else { return nil }
                return DataElement(date: date, itemsComplete: Double($1.count))
            }
            .sorted {
                $0.date < $1.date
            }
    }
}

extension ChartData {
    
    /// Some static sample data for displaying a `Chart`.
    static var chartSampleData: [DataElement] {
        let calendar = Calendar.autoupdatingCurrent
        var startDateComponents = calendar.dateComponents(
            [.year, .month, .day], from: Date())
        startDateComponents.setValue(22, for: .day)
        startDateComponents.setValue(5, for: .month)
        startDateComponents.setValue(2022, for: .year)
        startDateComponents.setValue(0, for: .hour)
        startDateComponents.setValue(0, for: .minute)
        startDateComponents.setValue(0, for: .second)
        let startDate = calendar.date(from: startDateComponents)!
        
        let itemsToAdd = [
            6, 3, 1, 4, 1, 2, 7,
            5, 2, 0, 5, 2, 3, 9
        ]
        var items = [DataElement]()
        for dayOffset in (0..<itemsToAdd.count) {
            items.append(DataElement(
                date: calendar.date(byAdding: .day, value: dayOffset, to: startDate)!,
                itemsComplete: Double(itemsToAdd[dayOffset])))
        }
        
        return items
    }
}
